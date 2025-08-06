mod config;
mod logs;
mod game;
mod tx_handlers;

use balius_sdk::{ FnHandler, Worker };
use firefly_balius::{
    balius_sdk::{self}, WorkerExt as _
};

#[balius_sdk::main]
fn main() -> Worker {
    Worker::new()
        .with_request_handler("logs", FnHandler::from(logs::query_logs))
        .with_request_handler("clear_logs", FnHandler::from(logs::clear_logs))
        .with_request_handler("set_system_address", FnHandler::from(config::set_system_address))
        .with_request_handler("config", FnHandler::from(config::query_config))
        .with_request_handler("create_game", FnHandler::from(game::create_game))
        .with_request_handler("clear_games", FnHandler::from(game::clear_games))
        .with_request_handler("set_game_winners", FnHandler::from(game::set_winners))
        .with_request_handler("get_games", FnHandler::from(game::get_games))
        .with_request_handler("send_rewards", FnHandler::from(game::send_rewards))
        .with_tx_submitted_handler(tx_handlers::handle_submit)
        // .with_utxo_handler(UtxoMatcher::all(), FnHandler::from(tx_handlers::handle_utxo))
        // .with_tx_handler(UtxoMatcher::all(), FnHandler::from(tx_handlers::handle_tx))
}
