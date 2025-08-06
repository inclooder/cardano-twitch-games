use crate::balius_sdk::{WorkerResult, Config, Params, Json};
use firefly_balius::kv;
use serde::{Serialize, Deserialize};

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct LogsKv {
    logs: Vec<String>
}

pub fn log(msg: &str) -> WorkerResult<()> {
    let mut logs: Vec<String> = kv::get("logs")?.unwrap_or_default();

    logs.push(msg.to_owned());

    kv::set("logs", &logs)?;

    Ok(())
}

pub fn query_logs(_: Config<()>, _: Params<()>) -> WorkerResult<Json<Vec<String>>> {
    Ok(Json(kv::get("logs")?.unwrap_or_default()))
}

pub fn clear_logs(_: Config<()>, _: Params<()>) -> WorkerResult<()> {
    let mut logs: Vec<String> = kv::get("logs")?.unwrap_or_default();

    logs.clear();

    kv::set("logs", &logs)?;

    Ok(())
}
