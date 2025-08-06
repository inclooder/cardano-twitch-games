# 🎮 Cardano Twitch Games

A platform that enables Twitch streamers and influencers to host giveaways using Cardano blockchain assets.

This project leverages **Hyperledger FireFly** and the **Cardano connector** to handle blockchain operations, while a **Godot**-powered game client provides an interactive front end. The system selects winners and distributes prizes in a seamless, automated way.

> 🔗 Currently, there are no platforms tailored for influencer-driven Cardano giveaways — this project aims to fill that gap.

---

## 🛠️ Tech Stack

- [Hyperledger FireFly](https://hyperledger.org/projects/firefly)  
- Cardano FireFly Connector  
- [Godot Game Engine](https://godotengine.org)

---

## 🚀 Installation & Setup

### 1. Install FireFly and the `ff` CLI utility

Follow the official [FireFly installation guide](https://hyperledger.github.io/firefly/) for your system.

### 2. Initialize Cardano Stack

```sh
BLOCKFROST_KEY=paste-your-blockfrost-key-here

ff init cardano --blockfrost-key $BLOCKFROST_KEY --network preprod
```

### 3. Start the Cardano Stack

```sh
ff start <stack-name>
```

### 4. Deploy the Bailus Smart Contract

```sh
cd scripts/deploy-contract
cargo run --bin firefly-cardano-deploy-contract -- --contract-path ../../contract
cd -
```

### 5. Launch the Godot Game

Open the project `streamgames` with the Godot Engine.

### 6. Retrieve Wallet Address

Use the following command:

```sh
ff accounts list <stack-name>
```

### 7. Configure Wallet in Game

- In the game, click on **Settings**.
- Paste your wallet address.
- Click **Save**.

### 8. Start a Game

Click **New Game** to begin hosting giveaways and interacting with your Twitch audience!

---

## 📈 Future Plans

- 🎲 Add more mini-games  
- 🏆 Create a global leaderboard  
- 🔗 Integrate with the Twitch API (e.g. allow users to set their wallet address and display name via chat)  
- 🖼️ Add support for NFTs  
