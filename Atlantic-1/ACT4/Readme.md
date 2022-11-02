## Guide for batch txh on Vortex
- Set your wallet name and wallet address
```
SEI_ADDR=YOUR_WALLET_ADDR
wallet=YOUR_WALLET_NAME
SETUP_PATH=YOUR_PATH_stores_SCRIPTS
echo "export PATH=$PATH:$YOUR_PATH" >> $HOME/.bash_profile
source $HOME/.bash_profile
```
- Download all script files (`*.json`, `*.sh`) to `SETUP_PATH`

- Replace your address into script
```
sed -i "s|^SEI_ADDR=.*|SEI_ADDR=$SEI_ADDR|" vortex_limit.sh
sed -i "s|^SEI_ADDR=.*|SEI_ADDR=$SEI_ADDR|" vortex_market.sh
sed -i "s|^SEI_ADDR=.*|SEI_ADDR=$SEI_ADDR|" vortex_bundle.sh
sed -i "s|^wallet=.*|wallet=$wallet|" vortex_bundle.sh
sed -i "s|^wallet=.*|wallet=$wallet|" vortex_limit.sh
sed -i "s|^wallet=.*|wallet=$wallet|" vortex_market.sh

sed -i "s|\"creator\": .*|\"creator\": \"$SEI_ADDR\",|" gen_limit_tx.json
sed -i "s|\"creator\": .*|\"creator\": \"$SEI_ADDR\",|" gen_market_tx.json
sed -i "s|\"creator\": .*|\"creator\": \"$SEI_ADDR\",|" gen_bundle_tx.json
sed -i "s|\"account\": .*|\"account\": \"$SEI_ADDR\",|" gen_limit_tx.json
sed -i "s|\"account\": .*|\"account\": \"$SEI_ADDR\",|" gen_market_tx.json
sed -i "s|\"account\": .*|\"account\": \"$SEI_ADDR\",|" gen_bundle_tx.json

sed -i "s|SEI_ACT4$|$SETUP_PATH|g" vortex_bundle.sh
sed -i "s|SEI_ACT4$|$SETUP_PATH|g" vortex_market.sh
sed -i "s|SEI_ACT4$|$SETUP_PATH|g" vortex_limit.sh
```

- Run script then check txh
- Setup crontab 
```
0 * * * * /root/SEI_ACT4/vortex_bundle.sh
17 * * * * /root/SEI_ACT4/vortex_limit.sh
32 * * * * /root/SEI_ACT4/vortex_market.sh
```

- Check recorded txh in `$SETUP_PATH/txh.log` 
