use std::collections::HashSet;
use std::str::FromStr;

use crate::{config::ConfigKv, game::set_game_tx_hash};

use balius_sdk::{
    Ack, Config, FnHandler, Params, Worker, WorkerResult, UtxoMatcher, Utxo, Tx,
    txbuilder::{
        AddressPattern, BuildError, FeeChangeReturn, OutputBuilder, TxBuilder, UtxoPattern,
        UtxoSource
    }
};
use balius_sdk::txbuilder::Address;
use firefly_balius::{
    balius_sdk::{self, Json}, emit_events, kv, CoinSelectionInput, Event, EventData, FinalizationCondition, NewMonitoredTx, SubmittedTx, WorkerExt as _
};
use serde::{Deserialize, Serialize};

//Kv Structs
#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct CurrentState {
    submitted_txs: HashSet<String>,
}

pub fn handle_utxo(_: Config<()>, utxo: Utxo<serde_json::Value>) -> WorkerResult<Ack> {
    let config_kv: ConfigKv = kv::get("config")?.unwrap_or_default();

    if let Some(Ok(deposit_address)) = config_kv.system_address.map(|a| Address::from_str(a.as_str())) {
        let address = Address::from_bytes(&utxo.utxo.address).map_err(|_| BuildError::MalformedAddress)?;

        if address == deposit_address {
            let tx_hash = hex::encode(utxo.tx_hash.clone());

            let event_data = DepositTxReceived { tx_hash };

            emit_events(
                vec![Event::new(&utxo, &event_data)?]
            )?;
        }
    }

    Ok(Ack)
}

pub fn handle_tx(_: Config<()>, tx: Tx) -> WorkerResult<Ack> {
    let tx_hash = hex::encode(tx.hash.clone());

    let event_data = TxReceived { tx_hash };

    let event = Event {
        block_hash: tx.block_hash.clone(),
        tx_hash: tx.hash.clone(),
        signature: event_data.signature(),
        data: serde_json::to_value(event_data)?
    };

    emit_events(
        vec![event]
    )?;

    Ok(Ack)
}

/// This function is called when a TX produced by this contract is submitted to the blockchain, but before it has reached a block.
pub fn handle_submit(_: Config<()>, tx: SubmittedTx) -> WorkerResult<Ack> {
    // Keep track of which TXs have been submitted.
    let mut state: CurrentState = kv::get("current_state")?.unwrap_or_default();
    state.submitted_txs.insert(tx.hash.clone());
    kv::set("current_state", &state)?;

    set_game_tx_hash(tx.hash)?;

    Ok(Ack)
}

#[derive(Serialize, Deserialize, Clone)]
struct Datum {}

#[derive(Serialize)]
struct DepositTxReceived {
    tx_hash: String,
}

impl EventData for DepositTxReceived {
    fn signature(&self) -> String {
        "DepositTxReceived(string)".to_string()
    }
}

#[derive(Serialize)]
struct TxReceived {
    tx_hash: String,
}

impl EventData for TxReceived {
    fn signature(&self) -> String {
        "TxReceived(string)".to_string()
    }
}
