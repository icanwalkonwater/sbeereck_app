use dotenv_codegen::dotenv;
use firestore_db_and_auth::{
    documents, documents::List, sessions::service_account::Session, ServiceSession,
};
use google_sheets4::Sheets;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

#[repr(i32)]
#[derive(Debug, Eq, PartialEq, Hash, Copy, Clone)]
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
    UNKNOWN,
}

impl FromStr for School {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(match s.to_lowercase().as_str() {
            "ensimag" => School::ENSIMAG,
            "phelma" => School::PHELMA,
            "e3" => School::E3,
            "papet" => School::PAPET,
            "gi" => School::GI,
            "polytech" => School::POLYTECH,
            "esisar" => School::ESISAR,
            "iae" => School::IAE,
            "uga" => School::UGA,
            _ => School::UNKNOWN,
        })
    }
}

#[derive(Debug, Clone)]
struct SheetAccount {
    last_name: String,
    first_name: String,
    school: School,
    is_member: bool,
    balance: f32,
    normal: u32,
    special: u32,
    recharge: f32,
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

impl From<SheetAccount> for FirestoreAccount {
    fn from(sheet: SheetAccount) -> Self {
        FirestoreAccount {
            last_name: sheet.last_name,
            first_name: sheet.first_name,
            school: sheet.school as _,
            is_member: sheet.is_member,
            balance: (sheet.balance * 100.0).round() as _,
            stats: FirestoreAccountStats {
                quantity_drank: (sheet.normal + sheet.special) as _,
                total_money: (sheet.recharge * 100.0).round() as _,
            },
        }
    }
}

async fn sheets_init() -> Sheets {
    let secret = yup_oauth2::read_application_secret("google_key.json")
        .await
        .expect("Failed to get app secret !");

    let auth = yup_oauth2::InstalledFlowAuthenticator::builder(
        secret,
        yup_oauth2::InstalledFlowReturnMethod::HTTPRedirect,
    )
    .persist_tokens_to_disk("google_key_cache.json")
    .build()
    .await
    .unwrap();

    let hub = Sheets::new(
        hyper::Client::builder().build(hyper_rustls::HttpsConnector::with_native_roots()),
        auth,
    );

    hub
}

fn parse_money(raw: &str) -> f32 {
    raw.chars()
        .take_while(|&c| c != ' ' && c != '€')
        .collect::<String>()
        .replace(",", ".")
        .parse()
        .unwrap()
}

async fn sheets_get_all(hub: Sheets) -> Vec<SheetAccount> {
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
}

fn firestore_init() -> Session {
    let mut credentials =
        firestore_db_and_auth::Credentials::from_file("firebase_service_account.json")
            .expect("Failed read firebase credentials");

    credentials
        .download_google_jwks()
        .expect("Failed to download public keys");

    ServiceSession::new(credentials).expect("Failed to create session")
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    dotenv::dotenv().expect("Failed to initialize dotenv");
    let sheets = sheets_init().await;
    let accounts = sheets_get_all(sheets).await;

    for a in &accounts[..10] {
        println!("{:?}", a);
        println!("{:?}", FirestoreAccount::from(a.clone()))
    }
    println!("...and {} more", accounts.len() - 10);

    let firestore = firestore_init();
    let accounts: List<FirestoreAccount, _> = documents::list(&firestore, "accounts");
    for a in accounts {
        let (doc, _) = a.unwrap();
        println!("{:?}", doc);
    }
}
