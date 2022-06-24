#!/bin/bash

#. <(curl -s https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/logo.sh)

#sudo apt update
#sudo apt install -y make gcc jq curl git

#if [ ! -f "/usr/local/go/bin/go" ]; then
#  . <(curl -s "https://raw.githubusercontent.com/nodejumper-org/cosmos-utils/main/utils/go_install.sh")
#  . .bash_profile
#fi
#go version # go version goX.XX.X linux/amd64

#cd || return
#rm -rf sei-chain
#git clone https://github.com/sei-protocol/sei-chain.git
#cd sei-chain || return
#git checkout 1.0.4beta
#make install
#seid version

echo -e "\e[1m\e[32mEnter your nodename \e[0m"
read -p "Nodename: " NODENAME

echo -e "\e[1m\e[32mEnter your SEI ID \e[0m"
read -p "Install Sei ID (exp: sei2: " SEI_ID

mkdir $HOME/$SEI_ID
cp /root/go/bin/seid /root/go/bin/$SEI_ID

# replace nodejumper with your own moniker, if you'd like
seid config chain-id sei-testnet-2 --home $HOME/$SEI_ID
seid init $NODENAME --chain-id sei-testnet-2 -o --home $HOME/$SEI_ID

curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-2/genesis.json > $HOME/$SEI_ID/config/genesis.json
sha256sum $HOME/$SEI_ID/config/genesis.json # aec481191276a4c5ada2c3b86ac6c8aad0cea5c4aa6440314470a2217520e2cc

curl https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-2/addrbook.json > $HOME/$SEI_ID/config/addrbook.json
sha256sum $HOME/$SEI_ID/config/addrbook.json # 9058b83fca36c2c09fb2b7c04293382084df0960b4565090c21b65188816ffa6

sed -i 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.0001usei"|g' $HOME/$SEI_ID/config/app.toml
seeds=""
peers="f4b1aa3416073a4493de7889505fc19777326825@rpc1-testnet.nodejumper.io:28656,38b4d78c7d6582fb170f6c19330a7e37e6964212@194.163.189.114:46656,5b5ec09067a5fcaccf75f19b45ab29ce07e0167c@18.118.159.154:26656,b20fa6b0a283e153c446fd58dd1e1ae56b09a65d@159.69.110.238:26656,613f6f5a67c4f0625599ca74b98b7d722f908262@159.65.195.25:36376,1c384cbe9421957813f49865bb8db8c190a90415@139.59.38.171:36376,8b5d1f7d5422e373b00c129ccda14556b69e2a61@167.235.21.137:26656,8c4ec366b5ebd182ffe463e3e1a3a6a345d7d1eb@80.82.215.233:26656,214d45c890cccc09ee725bd101a60dcd690cd554@49.12.215.72:26676,d87dcc1d6b5517b4da9a1ca48717a68ee3bd1d6a@89.163.215.204:26656,fed3ec8e12ddde3fc8e90efc1746e55d10a623f0@65.109.11.114:26656"
sed -i -e 's|^seeds *=.*|seeds = "'$seeds'"|; s|^persistent_peers *=.*|persistent_peers = "'$peers'"|' $HOME/$SEI_ID/config/config.toml

# in case of pruning
sed -i 's|pruning = "default"|pruning = "custom"|g' $HOME/$SEI_ID/config/app.toml
sed -i 's|pruning-keep-recent = "0"|pruning-keep-recent = "100"|g' $HOME/$SEI_ID/config/app.toml
sed -i 's|pruning-interval = "0"|pruning-interval = "10"|g' $HOME/$SEI_ID/config/app.toml

sudo tee /etc/systemd/system/$SEI_ID.service > /dev/null << EOF
[Unit]
Description=Sei Protocol Node $SEI_ID
After=network-online.target
[Service]
User=$USER
ExecStart=$(which $SEI_ID) start --home $HOME/$SEI_ID/
Restart=on-failure
RestartSec=10
LimitNOFILE=10000
[Install]
WantedBy=multi-user.target
EOF

seid tendermint unsafe-reset-all --home $HOME/$SEI_ID --keep-addr-book

SNAP_RPC1="http://173.212.215.104:26357" \
SNAP_RPC2="http://173.212.215.104:26357"

LATEST_HEIGHT=$(curl -s $SNAP_RPC2/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 700)); \
TRUST_HASH=$(curl -s "$SNAP_RPC2/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC1,$SNAP_RPC2\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/$SEI_ID/config/config.toml

peers="f6c80c797ab4b3161fbf758ed23573c11ea5d559@173.212.215.104:26356"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/$SEI_ID/config/config.toml

sudo tee <<EOF >/dev/null /etc/systemd/journald.conf
Storage=persistent
EOF

#SNAP_RPC="http://rpc1-testnet.nodejumper.io:28657"
#LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
#BLOCK_HEIGHT=$((LATEST_HEIGHT - 2000)); \
#TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

#echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

#sed -i -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
#s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
#s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
#s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"|" $HOME/$SEI_ID/config/config.toml

sudo systemctl daemon-reload
sudo systemctl enable $SEI_ID
#sudo systemctl restart seid
