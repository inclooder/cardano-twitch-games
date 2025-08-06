use crate::balius_sdk::{
    WorkerResult, Config, Params, Json, Ack,
    txbuilder::{Address, BuildError}
};
use firefly_balius::kv;
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct ConfigKv {
    pub system_address: Option<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SetSystemAddressRequest {
    pub address: String,
}

pub fn query_config(_: Config<()>, _: Params<()>) -> WorkerResult<Json<ConfigKv>> {
    Ok(Json(kv::get("config")?.unwrap_or_default()))
}

pub fn set_system_address(_: Config<()>, req: Params<SetSystemAddressRequest>) -> WorkerResult<Ack> {
    let _from_address = Address::from_bech32(&req.address).map_err(|_| BuildError::MalformedAddress)?;

    let mut config_kv: ConfigKv = kv::get("config")?.unwrap_or_default();

    config_kv.system_address = Some(req.address.clone());

    kv::set("config", &config_kv)?;

    Ok(Ack)
}
