## 1. PREREQUISTE
- As we know that, validator node play a important role in Cosmos network. Validator consensus private key is stored in plain text format in validator node and easy to be compromised if someone takes control of validator node.
- In this guide, i will guide how to setup Tendermint Key Management Service (called TMKMS) in below scenario
  + There are 2 different servers which connect via Wireguard VPN, below is detail for setup Wireguard VPN between 2 server on Ubuntu
    - [Wireguard setup guide on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-set-up-wireguard-on-ubuntu-20-04)
  + One server will be installed TMKMS to encrypt validator consensus key and sign block remotely.
  + The other server will communicate TMKMS server, but not sign block
  + There is no validator consensus key in plain text format on both server, so no need to worry compromised validator related issue

## 2. TMKMS NODE SETUP PART
### 2.1 Install the following dependencies
```
# RUST
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# GCC
sudo apt update
sudo apt install git build-essential ufw curl jq snapd --yes

# Libusb
apt install libusb-1.0-0-dev

# If on x86_64 architecture, then run below command
uname -i
export RUSTFLAGS=-Ctarget-feature=+aes,+ssse3
echo "export RUSTFLAGS=-Ctarget-feature=+aes,+ssse3" >> $HOME/.bash_profile
```

### 2.2 Clone repo and setup TMKMS
- Download and install TMKMS
```
# ======================================================================
# The following signing backend providers are presently supported:
# Hardware Security Modules (recommended)
#   - YubiHSM2 (gated under the yubihsm cargo feature. See README.yubihsm.md for more info)
#   - Ledger (gated under the ledgertm cargo feature)
# Software-Only (not recommended)
#   - softsign backend which uses ed25519-dalek
# Guide is for compiling source code using the --features=softsign flag
# ======================================================================
cd $HOME
git clone https://github.com/iqlusioninc/tmkms.git
cd $HOME/tmkms
cargo install tmkms --features=softsign
```
- Initilize TMKMS, then it will generate a `tmkms.toml` file, a `kms-identity.key` (used to authenticate the KMS to the validator), and create 2 subdirectories `secrets` and `state` .
```
cd $HOME/tmkms
tmkms init config
```
>   Creating config   
>   Generated KMS configuration: /root/tmkms/config/tmkms.toml  
>   Generated Secret Connection key: /root/tmkms/config/secrets/kms-identity.key  

- Create a software signing key
```
tmkms softsign keygen ./config/secrets/secret_connection_key
```
> Generated consensus (Ed25519) private key at: ./config/secrets/secret_connection_key

- Upload `priv_validator_key.json` on your validator node to TMKMS node at the path $HOME/tmkms/config/secrets/
> ![image](https://user-images.githubusercontent.com/91453629/195241414-14dea418-89d1-4e4a-9b8b-8f3ed9d6c277.png)

- Import the private validator key into TMKMS
```
tmkms softsign import $HOME/tmkms/config/secrets/priv_validator_key.json $HOME/tmkms/config/secrets/priv_validator_key
```
> INFO tmkms::commands::softsign::import: Imported Ed25519 private key to /root/tmkms/config/secrets/priv_validator_key

- The new file `priv_validator_key` has been created in the path `$HOME/tmkms/config/secrets/`. Please note at this point, download the file `priv_validator_key.json` to store offline on your computer, then you can delete the file on both your validator node and tmkms node. This newly created `priv_validator_key` will be what TMKMS will use to sign for your validator. 
> ![image](https://user-images.githubusercontent.com/91453629/195242342-3e23ff29-f11a-45f0-8d94-c7ab51ee8dcd.png)

- Edit `$HOME/tmkms/config/tmkms.toml` as below to be used for your chain (in this guide i use the chain-id `atlantic-1` as example
```
[[chain]]
id = "atlantic-1"
key_format = { type = "cosmos-json", account_key_prefix = "seipub", consensus_key_prefix = "seivalconspub" }
state_file = "/root/tmkms/config/state/priv_validator_state.json"

## Signing Provider Configuration

### Software-based Signer Configuration

[[providers.softsign]]
chain_ids = ["atlantic-1"]
key_type = "consensus"
path = "/root/tmkms/config/secrets/priv_validator_key"

## Validator Configuration

[[validator]]
chain_id = "atlantic-1"
addr = "tcp://YOUR_NODE_IP:688"
secret_key = "/root/tmkms/config/secrets/secret_connection_key"
protocol_version = "v0.34"
reconnect = true
```

- Create systemd of TMKMS server
```
sudo tee /etc/systemd/system/tmkms.service > /dev/null <<EOF
[Unit]
Description=Tendermint KMS
After=network-online.target

[Service]
User=$USER
ExecStart=$(which tmkms) start -c /root/tmkms/config/tmkms.toml
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
```

## 3. VALIDATOR NODE SETUP PART
- Edit configuration data of your chain on validator node
```
sed -i.bak -E "s|^priv_validator_laddr .*|priv_validator_laddr = \"tcp\:\/\/0\.0\.0\.0\:688\"|" $HOME/.sei/config/config.toml
sed -i.bak -E "s|^priv_validator_key_file|# priv_validator_key_file|" $HOME/.sei/config/config.toml
sed -i.bak -E "s|^priv_validator_state_file|# priv_validator_state_file|" $HOME/.sei/config/config.toml
```

## 4. START PROCESS
- Stop your validator node
```
systemctl stop seid && journalctl -u seid -f -o cat
```

- Start TMKMS process on TMKMS node, then KMS log will be as below. You can see that consensus key of your validator node has been added to TMKMS (Tip: You can check `pub_key` in original file `priv_validator_key.json`)
```
sudo systemctl daemon-reload
sudo systemctl enable tmkms
sudo systemctl restart tmkms && sudo journalctl -fu tmkms -o cat
```
> ![image](https://user-images.githubusercontent.com/91453629/195250267-3476a595-cb3d-4d32-8ca8-bb1cdb1f141d.png)

- Restart your validator node (below is example of sei mainchain `atlantic-1`)
```
sudo systemctl restart seid && sudo journalctl -fu seid -o cat
```
> ![image](https://user-images.githubusercontent.com/91453629/195245567-eef48ad1-af3c-452a-9cba-f39a42e537d3.png)

- Check TMKMS log, now TMKMS can handshake with validator node and start signing of block
> ![image](https://user-images.githubusercontent.com/91453629/195245851-4c58a07a-0fbb-4f52-ace4-8b5711b90177.png)
> ![image](https://user-images.githubusercontent.com/91453629/195246093-d1f7df9b-0f72-4179-9cbf-53c770826dfe.png)

- Check consensus key of your validator node. Expected result is `Same key`
```
[[ $(seid q staking validator seivaloper1j3pzhu2400f4ntv6kznlvramxv62w2d2hj7e4u -oj | jq -r .consensus_pubkey.key) = $(seid status | jq -r .ValidatorInfo.PubKey.value) ]] && echo "Same key" || echo "Different key"
```
> ![image](https://user-images.githubusercontent.com/91453629/195248665-a3b55ebd-bbf3-4e90-87c0-1d13ca75855e.png)

- Check `pub_key` in newly created `priv_validator_key.json`, it will be different with `pub_key` of validator node and in original file `priv_validator_key.json`
> ![image](https://user-images.githubusercontent.com/91453629/195249718-01bb7cb1-b3e0-4c33-8687-a11f6fcd9d83.png)

- Now your validator key has been protected safely offline. Remember to remove the validator json keyfile from your validator node and TMKMS node completely. 

## 5. Setup using ssh-keygen on both of validator node and tmkms node
- This part will be deployed on both of nodes.

### 5.1 Change SSH default port to specific port from 1024 and 65536. 
```
sed -i.bak -e 's|#Port 22|Port 3012|g' /etc/ssh/sshd_config
systemctl restart sshd
```

### 5.2 Seting to remote login server based on SSH Key
- On your local computer, create a pair of public/private SSH key
```
ssh-keygen
```

- Upload public key `/root/.ssh/id_rsa.pub` in your local server to validator and tmkms servers
```
cat $HOME/.ssh/id_rsa.pub | ssh root@YOUR_SERVER_IP "mkdir -p /root/.ssh && cat >> /root/.ssh/authorized_keys"
```

- Try to login the remote server by SSH key from your local server with newly SSH_PORT `3012` in step 2
```
ssh root@YOUR_SERVER_IP -p 3012
```

- Disabling Password Authentication on your Server
```
sed -i.bak -e 's|#PasswordAuthentication yes|PasswordAuthentication no|g' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 5.3 Install Fail2ban to prevent Brute Force Atk (optional)
