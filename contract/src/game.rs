use balius_sdk::{
    Ack, Config, Params, WorkerResult, Json,
    txbuilder::{Address, BuildError, AddressPattern, UtxoSource, UtxoPattern, TxBuilder, FeeChangeReturn, OutputBuilder},
};
use firefly_balius::{
    balius_sdk::{self}, kv, CoinSelectionInput, FinalizationCondition, NewMonitoredTx, WorkerExt as _
};
use serde::{Deserialize, Serialize};
use crate::config::ConfigKv;
use std::collections::HashMap;

#[derive(Serialize, Deserialize, Default, Clone, Copy)]
#[serde(rename_all = "camelCase")]
enum GameState {
    #[default]
    Init,
    RewardsSent,
}

#[derive(Serialize, Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
enum GameReward {
    Ada(u64),
    NativeAsset {
        policy_id: String,
        asset_name: String,
        quantity: u64,
    }
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Game {
    name: String,
    state: GameState,
    rewards: Vec<GameReward>,
    participants: Vec<String>,
    winners: Vec<String>,
    tx_hash: Option<String>,
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct Player {
    name: String,
    address: String,
    points: u64,
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
struct PlayersKv {
    players: HashMap<String, Player>,
}

#[derive(Serialize, Deserialize, Default)]
#[serde(rename_all = "camelCase")]
pub struct GamesKv {
    pub games: Vec<Game>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct NewGameRequest {
    name: String,
    rewards: Vec<GameReward>,
    participants: Vec<String>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SetWinnersRequest {
    winners: Vec<String>,
}

pub fn create_game(_: Config<()>, req: Params<NewGameRequest>) -> WorkerResult<Ack> {
    let mut games_kv: GamesKv = kv::get("games")?.unwrap_or_default();

    // let last_game = games_kv.games.last();
    //
    // if let Some(game) = last_game {
    //     match game.state {
    //         GameState::Init => {
    //             return Err(balius_sdk::Error::Internal("Waiting for previous game to finish".to_string()))
    //         },
    //         _ => {}
    //     }
    // }

    let mut games = games_kv.games;

    for participant in req.participants.iter() {
        let _ = Address::from_bech32(participant).map_err(|_| BuildError::MalformedAddress)?;
    }

    games.push(
        Game { 
            name: req.name.clone(),
            state: GameState::Init,
            rewards: req.rewards.clone(), 
            participants: req.participants.clone(),
            ..Game::default()
        }
    );

    games_kv.games = games;

    kv::set("games", &games_kv)?;

    Ok(Ack)
}

pub fn set_winners(_: Config<()>, req: Params<SetWinnersRequest>) -> WorkerResult<Ack> {
    let mut games_kv: GamesKv = kv::get("games")?.unwrap_or_default();

    let game: &mut Game = games_kv.games.last_mut().ok_or(balius_sdk::Error::Internal("Game doesnt exist".to_string()))?;

    match game.state {
        GameState::Init => {
            game.winners = req.winners.clone();
            kv::set("games", &games_kv)?;
        },
        _ => {
            return Err(balius_sdk::Error::Internal("Invalid game state".to_string()))
        }
    }

    let _ = kv::set("games", &games_kv);

    Ok(Ack)
}

pub fn send_rewards(_: Config<()>, req: Params<()>) -> WorkerResult<NewMonitoredTx> {
    let mut games_kv: GamesKv = kv::get("games")?.unwrap_or_default();

    let game: &mut Game = games_kv.games.last_mut().ok_or(balius_sdk::Error::Internal("Game doesnt exist".to_string()))?;

    match game.state {
        GameState::Init => {},
        _ => {
            return Err(balius_sdk::Error::Internal("Invalid game state".to_string()))
        }
    }

    if game.rewards.is_empty() {
        return Err(balius_sdk::Error::Internal("Nothing to reward".to_string()))
    }

    if game.winners.is_empty() {
        return Err(balius_sdk::Error::Internal("Winners not set".to_string()))
    }

    let mut tx = TxBuilder::new();

    let mut total_ada: u64 = 0;

    let mut player_position = 0;
    for reward in game.rewards.iter() {
        if let Some(player) = game.winners.get(player_position) {
            let _user_addr = Address::from_bech32(&player).map_err(|_| BuildError::MalformedAddress)?;
            match reward {
                GameReward::Ada(amount) => {
                    tx = tx.with_output(
                        OutputBuilder::new().address(player.clone()).with_value(*amount)
                    );
                    total_ada += amount;
                },
                GameReward::NativeAsset { policy_id, asset_name, quantity } => {
                }
            }
        }

        player_position += 1;
    }

    let config_kv: ConfigKv = kv::get("config")?.unwrap_or_default();
    let system_address = config_kv.system_address.ok_or(balius_sdk::Error::Internal("Game doesnt exist".to_string()))?;
    let from_address = Address::from_bech32(&system_address).map_err(|_| BuildError::MalformedAddress)?;

    let address_source = UtxoSource::Search(UtxoPattern {
        address: Some(AddressPattern {
            exact_address: from_address.to_vec(),
        }),
        ..UtxoPattern::default()
    });

    tx = tx.with_input(CoinSelectionInput(address_source.clone(), total_ada))
        .with_output(FeeChangeReturn(address_source));

    game.state = GameState::RewardsSent;
    let _ = kv::set("games", &games_kv);

    Ok(NewMonitoredTx(
        Box::new(tx),
        FinalizationCondition::AfterBlocks(2),
    ))
}

pub fn get_games(_: Config<()>, _: Params<()>) -> WorkerResult<Json<Vec<Game>>> {
    let games_kv: GamesKv = kv::get("games")?.unwrap_or_default();

    Ok(Json(games_kv.games))
}

pub fn clear_games(_: Config<()>, _: Params<()>) -> WorkerResult<Ack> {
    let _ = kv::set("games", &GamesKv::default());

    Ok(Ack)
}

pub fn set_game_tx_hash(tx_hash: String) -> WorkerResult<Ack> {
    let mut games_kv: GamesKv = kv::get("games")?.unwrap_or_default();
    let game: &mut Game = games_kv.games.last_mut().ok_or(balius_sdk::Error::Internal("Game doesnt exist".to_string()))?;

    game.tx_hash = Some(tx_hash);

    let _ = kv::set("games", &games_kv);

    Ok(Ack)
}
