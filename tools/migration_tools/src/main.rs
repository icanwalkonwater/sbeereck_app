#![feature(path_try_exists)]

use anyhow::{anyhow, bail};
use dialoguer::{theme::ColorfulTheme, Confirm, Input, Select};
use firestore_db_and_auth::{
    documents,
    documents::{List, WriteOptions},
    sessions::service_account::Session,
    ServiceSession,
};
use indicatif::{ProgressBar, ProgressIterator};
use serde::{Deserialize, Serialize};
use std::{
    fs::File,
    io::{Read, Write},
    path::Path,
};

#[repr(i32)]
#[derive(Debug, Eq, PartialEq, Hash, Copy, Clone, Deserialize)]
#[serde(rename_all(serialize = "lowercase"))]
enum School {
    ENSIMAG,
    PHELMA,
    E3,
    PAPET,
    GI,
    POLYTECH,
    ESISAR,
    IAE,
    UGA,
    #[serde(other)]
    UNKNOWN,
}

#[derive(Debug, Clone, Deserialize)]
struct CsvAccount {
    last_name: String,
    first_name: String,
    school: School,
    // tel: String,
    balance: f32,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct FirestoreAccount {
    last_name: String,
    first_name: String,
    school: i32,
    is_member: bool,
    balance: i32,
    stats: FirestoreAccountStats,
}

#[derive(Serialize, Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct FirestoreAccountStats {
    quantity_drank: f32,
    total_money: i32,
}

impl From<CsvAccount> for FirestoreAccount {
    fn from(csv: CsvAccount) -> Self {
        FirestoreAccount {
            last_name: csv.last_name,
            first_name: csv.first_name,
            school: csv.school as _,
            is_member: true,
            balance: (csv.balance * 100.0).round() as _,
            stats: FirestoreAccountStats {
                quantity_drank: 0.0,
                total_money: 0,
            },
            /*stats: FirestoreAccountStats {
                quantity_drank: (sheet.normal + sheet.special) as _,
                total_money: (sheet.recharge * 100.0).round() as _,
            },*/
        }
    }
}

fn firestore_init() -> anyhow::Result<Session> {
    let mut credentials =
        firestore_db_and_auth::Credentials::from_file("firebase_service_account.json")?;

    credentials.download_google_jwks()?;

    Ok(ServiceSession::new(credentials)?)
}

fn get_firestore_accounts() -> anyhow::Result<Vec<FirestoreAccount>> {
    let firestore = firestore_init()?;
    let accounts: List<FirestoreAccount, _> = documents::list(&firestore, "accounts");

    Ok(accounts
        .into_iter()
        .map(|acc| acc.map(|(doc, _)| doc).unwrap())
        .collect())
}

fn list_firestore_accounts() -> anyhow::Result<()> {
    let accounts = get_firestore_accounts()?;

    println!("Collected {} firestore accounts:", accounts.len());
    for acc in accounts {
        println!("{:?}", acc);
    }
    Ok(())
}

fn list_file_accounts() -> anyhow::Result<()> {
    let file = Input::with_theme(&ColorfulTheme::default())
        .with_prompt("Where is the account data ?")
        .default("accounts.csv".to_string())
        .show_default(true)
        .allow_empty(false)
        .validate_with(|input: &String| -> anyhow::Result<()> {
            Path::new(input).try_exists()?;
            Ok(())
        })
        .interact_text()?;

    let csv = csv::ReaderBuilder::new()
        .delimiter(',' as _)
        .from_path(file)?;

    let accounts = csv
        .into_deserialize()
        .map(|line| line.map_err(|e| anyhow!(e)))
        .collect::<anyhow::Result<Vec<CsvAccount>>>()?;

    println!("Collected {} accounts:", accounts.len());
    for acc in &accounts {
        println!("{:?}", acc);
    }

    let confirm = Confirm::with_theme(&ColorfulTheme::default())
        .with_prompt("Do you want to see them converted ?")
        .default(false)
        .show_default(true)
        .interact()?;

    if !confirm {
        println!("Understandable, have a great day");
        return Ok(());
    }

    for acc in accounts {
        println!("{:?}", FirestoreAccount::from(acc));
    }

    Ok(())
}

fn backup_firestore_accounts() -> anyhow::Result<()> {
    let file = Input::with_theme(&ColorfulTheme::default())
        .with_prompt("Where to backup the data ?")
        .default("firestore_backup.json".to_string())
        .show_default(true)
        .allow_empty(false)
        .validate_with(|input: &String| -> anyhow::Result<()> {
            let path = Path::new(input);
            if path.is_dir() {
                bail!("You can't use a folder as destination !");
            }
            Ok(())
        })
        .interact_text()?;

    let progress = ProgressBar::new_spinner();
    progress.enable_steady_tick(120);

    progress.set_message("Creating file");
    let mut file = File::create(file)?;
    progress.inc(1);

    progress.set_message("Querying accounts");
    let accounts = get_firestore_accounts()?;
    progress.set_message(format!("Queried {} accounts", accounts.len()));
    progress.inc(1);

    progress.set_message("Writing to file");
    file.write_all(serde_json::to_string(&accounts)?.as_bytes())?;
    progress.finish_with_message("Done");
    Ok(())
}

fn restore_backup_firestore() -> anyhow::Result<()> {
    let file = Input::with_theme(&ColorfulTheme::default())
        .with_prompt("Where is the backup data ?")
        .default("firestore_backup.json".to_string())
        .show_default(true)
        .allow_empty(false)
        .validate_with(|input: &String| -> anyhow::Result<()> {
            Path::new(input).try_exists()?;
            Ok(())
        })
        .interact_text()?;

    let progress = ProgressBar::new_spinner();
    progress.enable_steady_tick(120);

    progress.set_message("Reading account data");
    let accounts = {
        let mut file = File::open(file)?;
        let mut data = String::new();
        file.read_to_string(&mut data)?;
        serde_json::from_str::<Vec<FirestoreAccount>>(&data)?
    };
    progress.finish();

    let confirm = Confirm::with_theme(&ColorfulTheme::default())
        .with_prompt(format!(
            "Do you really want to restore {} accounts ?",
            accounts.len()
        ))
        .default(false)
        .show_default(true)
        .interact()?;

    if !confirm {
        println!("Understandable, have a great day");
        return Ok(());
    }

    progress.reset();
    progress.enable_steady_tick(120);
    progress.set_message("Uploading accounts");
    let session = firestore_init()?;
    for acc in accounts.into_iter().progress() {
        documents::write(
            &session,
            "accounts",
            Option::<String>::None,
            &acc,
            WriteOptions::default(),
        )?;
    }
    progress.finish_with_message("Done");

    Ok(())
}

fn delete_firestore_accounts() -> anyhow::Result<()> {
    let confirm = Confirm::with_theme(&ColorfulTheme::default())
        .with_prompt("Do you really want to delete all accounts ?")
        .default(false)
        .show_default(true)
        .interact()?;

    if !confirm {
        println!("Understandable, have a great day");
        return Ok(());
    }

    let confirm = Confirm::with_theme(&ColorfulTheme::default())
        .with_prompt("Like for real ??")
        .default(false)
        .show_default(true)
        .interact()?;

    if !confirm {
        println!("Understandable, have a great day");
        return Ok(());
    }

    let progress = ProgressBar::new_spinner();
    progress.enable_steady_tick(120);

    progress.set_message("Querying accounts to delete");
    let session = firestore_init()?;
    let accounts: List<FirestoreAccount, _> = documents::list(&session, "accounts");

    progress.set_message("Deleting accounts");
    for acc in accounts {
        let (_, doc) = acc?;
        progress.inc(1);
        documents::delete(&session, documents::abs_to_rel(&doc.name), true)?;
    }

    println!("Adios amigos");

    Ok(())
}

fn append_accounts() -> anyhow::Result<()> {
    let file = Input::with_theme(&ColorfulTheme::default())
        .with_prompt("Where is the account data ?")
        .default("accounts.csv".to_string())
        .show_default(true)
        .allow_empty(false)
        .validate_with(|input: &String| -> anyhow::Result<()> {
            Path::new(input).try_exists()?;
            Ok(())
        })
        .interact_text()?;

    let progress = ProgressBar::new_spinner();
    progress.enable_steady_tick(120);

    progress.set_message("Reading and converting account data");
    let csv = csv::ReaderBuilder::new()
        .delimiter(',' as _)
        .from_path(file)?;

    let accounts = csv
        .into_deserialize()
        .map(|line| line.map_err(|e| anyhow!(e)))
        .collect::<anyhow::Result<Vec<CsvAccount>>>()?;
    let accounts = accounts
        .into_iter()
        .map(|acc| FirestoreAccount::from(acc))
        .collect::<Vec<_>>();
    progress.finish();

    let confirm = Confirm::with_theme(&ColorfulTheme::default())
        .with_prompt(format!(
            "Do you really want to append {} accounts ?",
            accounts.len()
        ))
        .default(false)
        .show_default(true)
        .interact()?;

    if !confirm {
        println!("Understandable, have a great day");
        return Ok(());
    }

    progress.reset();
    progress.enable_steady_tick(120);
    progress.set_message("Uploading accounts");
    let session = firestore_init()?;
    for acc in accounts.into_iter().progress() {
        documents::write(
            &session,
            "accounts",
            Option::<String>::None,
            &acc,
            WriteOptions::default(),
        )?;
    }
    progress.finish_with_message("Done");

    Ok(())
}

fn main() -> anyhow::Result<()> {
    let action = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("What do you want to do ?")
        .item("List current firebase accounts")
        .item("List accounts to add")
        .item("Backup firestore accounts")
        .item("Restore firestore backup")
        .item("Delete all firebase accounts")
        .item("Append accounts to firebase")
        .default(0)
        .interact()?;

    match action {
        0 => list_firestore_accounts()?,
        1 => list_file_accounts()?,
        2 => backup_firestore_accounts()?,
        3 => restore_backup_firestore()?,
        4 => delete_firestore_accounts()?,
        5 => append_accounts()?,
        _ => println!("Unknown option"),
    }

    // let sheets = sheets_init().await;
    //let accounts = sheets_get_all(sheets).await;

    /*for a in &accounts[..10] {
        println!("{:?}", a);
        println!("{:?}", FirestoreAccount::from(a.clone()))
    }
    println!("...and {} more", accounts.len() - 10);*/

    Ok(())
}
