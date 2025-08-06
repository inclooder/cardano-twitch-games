use std::{
    path::PathBuf,
    process::{Command, Output},
};

use anyhow::{Result, bail};
use clap::Parser;
use firefly::FireflyCardanoClient;
use wit_component::ComponentEncoder;

mod firefly;

#[derive(Parser)]
struct Args {
    #[arg(long)]
    contract_path: PathBuf,
    #[arg(long, default_value = "http://localhost:5102")]
    firefly_cardano_url: String,
    #[arg(long)]
    firefly_url: Option<String>,
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();

    let (name, version) = Command::new("cargo")
        .arg("pkgid")
        .current_dir(&args.contract_path)
        .exec()
        .and_then(|output| {
            let mut str = String::from_utf8(output.stdout)?;
            let end = str.split_off(str.rfind(['/', '\\']).unwrap() + 1);
            let (folder_name, rest) = end.split_once('#').unwrap();
            if let Some((name, version)) = rest.split_once('@') {
                Ok((name.to_string(), version.trim().to_string()))
            } else {
                Ok((folder_name.to_string(), rest.trim().to_string()))
            }
        })?;
    let address = format!("{name}@{version}");
    println!("Compiling {address}...");

    Command::new("cargo")
        .arg("build")
        .arg("--target")
        .arg("wasm32-unknown-unknown")
        .arg("--release")
        .current_dir(&args.contract_path)
        .exec()?;

    let filename = format!("{}.wasm", name.replace("-", "_"));
    let path = args
        .contract_path
        .join("target")
        .join("wasm32-unknown-unknown")
        .join("release")
        .join(filename);

    println!("Bundling {address} as WASM component...");
    let module = wat::Parser::new().parse_file(path)?;
    let component = ComponentEncoder::default()
        .validate(true)
        .module(&module)?
        .encode()?;
    let contract = hex::encode(&component);

    println!("Deploying {address} to FireFly...");
    let base_url = args.firefly_url.unwrap_or(args.firefly_cardano_url);
    let firefly = FireflyCardanoClient::new(&base_url);
    firefly.deploy_contract(&name, &version, &contract).await?;

    Ok(())
}

trait CommandExt {
    fn exec(&mut self) -> Result<Output>;
}

impl CommandExt for Command {
    fn exec(&mut self) -> Result<Output> {
        let output = self.output()?;
        if !output.stderr.is_empty() {
            eprintln!("{}", std::str::from_utf8(&output.stderr)?);
        }
        if !output.status.success() {
            bail!("command failed: {}", output.status);
        }
        Ok(output)
    }
}
