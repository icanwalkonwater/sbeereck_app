#![feature(path_try_exists)]

use anyhow::anyhow;
use dialoguer::{theme::ColorfulTheme, Input, Select};
use firestore_db_and_auth::{
    documents, documents::List, sessions::service_account::Session, ServiceSession,
};
use serde::{Deserialize, Serialize};
use std::path::Path;

#[repr(i32)]
#[derive(Debug, Eq, PartialEq, Hash, Copy, Clone, Deserialize)]
#[serde(rename_all = "lowercase")]
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
    tel: String,
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
    fn from(sheet: CsvAccount) -> Self {
        FirestoreAccount {
            last_name: sheet.last_name,
            first_name: sheet.first_name,
            school: sheet.school as _,
            is_member: true,
            balance: (sheet.balance * 100.0).round() as _,
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

fn parse_money(raw: &str) -> f32 {
    raw.chars()
        .take_while(|&c| c != ' ' && c != '€')
        .collect::<String>()
        .replace(",", ".")
        .parse()
        .unwrap()
}

fn list_accounts_to_add() -> anyhow::Result<Vec<CsvAccount>> {
    let file = Input::with_theme(&ColorfulTheme::default())
        .with_prompt("Where is the account data ?")
        .default("accounts.csv".to_string())
        .show_default(true)
        .allow_empty(false)
        .validate_with(|input: &String| -> anyhow::Result<()> {
            Ok(Path::new(input).try_exists().map(|_| ())?)
        })
        .interact_text()?;

    let csv = csv::ReaderBuilder::new()
        .delimiter(',' as _)
        .from_path(file)?;

    csv.into_deserialize()
        .map(|line| line.map_err(|e| anyhow!(e)))
        .collect()
}

/*async fn sheets_get_all(hub: Sheets) -> Vec<SheetAccount> {
    let (_, range) = hub
        .spreadsheets()
        .values_get(dotenv!("SHEETS_ID"), "Comptes!B2:O1548")
        .doit()
        .await
        .expect("Request failed");

    range
        .values
        .expect("No values with request")
        .into_iter()
        .map(|row| SheetAccount {
            last_name: row[0].clone(),
            first_name: row[1].clone(),
            school: row
                .get(2)
                .map(|c| School::from_str(c).unwrap())
                .unwrap_or(School::UNKNOWN),
            is_member: row.get(4).map(|c| c == "TRUE").unwrap_or(false),
            balance: row
                .get(6)
                .filter(|c| !c.is_empty())
                .map(|c| parse_money(c))
                .unwrap_or(0.0),
            normal: row
                .get(7)
                .filter(|c| !c.is_empty())
                .map(|c| c.parse().unwrap())
                .unwrap_or(0),
            special: row
                .get(8)
                .filter(|c| !c.is_empty())
                .map(|c| c.parse().unwrap())
                .unwrap_or(0),
            recharge: row
                .get(10)
                .filter(|c| !c.is_empty())
                .map(|c| parse_money(c))
                .unwrap_or(0.0),
        })
        .collect()
}*/

fn firestore_init() -> Session {
    let mut credentials =
        firestore_db_and_auth::Credentials::from_file("firebase_service_account.json")
            .expect("Failed read firebase credentials");

    credentials
        .download_google_jwks()
        .expect("Failed to download public keys");

    ServiceSession::new(credentials).expect("Failed to create session")
}

fn list_firestore_accounts() -> Vec<FirestoreAccount> {
    let firestore = firestore_init();
    let accounts: List<FirestoreAccount, _> = documents::list(&firestore, "accounts");

    accounts
        .into_iter()
        .map(|acc| acc.map(|(doc, _)| doc).unwrap())
        .collect()
}

fn main() -> anyhow::Result<()> {
    let action = Select::with_theme(&ColorfulTheme::default())
        .with_prompt("What do you want to do ?")
        .item("List current firebase accounts")
        .item("List accounts to add")
        .item("Delete all firebase account")
        .item("Append accounts to firebase")
        .default(0)
        .interact()?;

    match action {
        0 => {
            for acc in list_firestore_accounts() {
                println!("{:?}", acc);
            }
        }
        1 => {
            for acc in list_accounts_to_add()?.into_iter().take(10) {
                println!("{:?}", acc);
            }
        }
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
