# Comos_Sei_L1
**Guide hướng dẫn để setup 1 hoặc nhiều VM của Sei trên VPS**

**2. Hướng dẫn tạo nhiều VM Sei trên VPS**

**2.1 Điều kiện đầu tiên**: VPS đã cài đặt VM đầu tiên của Sei như hướng dẫn bước 1, và các gói SW cần thiết

**2.2 Tạo nhiều VM Sei:** 

**_2.2.1 Download và chạy script Sei-multi-VM.sh để tạo từng VM lần lượt_**

        wget https://raw.githubusercontent.com/viennguyenbkdn/Comos_Sei_L1/main/Sei-multi-VM.sh
        ./Sei-multi-VM.sh

**_2.2.2 Thực hiện đổi port trong file configure của từng VM_**

Giả sử ở bước 2.2.1, chúng ta đã nhập **NODENAME=VM-Seid-2** và **SEI-ID=seid2**, thì data sẽ được cài ở thư mục **/root/seid2**

Thực hiện tìm port cần đổi và thay đổi port. Thông thường các dự án xài Cosmos SDK thì thường xài chung default port của Tendermint là 2265x, 909x, 606x...
Vì thế tùy tình hình thực tế mà port có thể thay đổi trong lệnh (tốt nhất cứ chạy VM mới, show log và lỗi ở port nào thì tìm và đổi)

        cd $HOME/seid2/config && grep -n "909.*\|266.*\|1317\|606.*" *.toml | grep -v persistent_peers
 
 Kết quả thực hiện lệnh sẽ như sau
 
        root@vmi843831:~/seid2/config# cd $HOME/seid2/config && grep -n "909.*\|266.*\|1317\|606.*" *.toml | grep -v persistent_peers
        app.toml:114:address = "tcp://0.0.0.0:1317"
        app.toml:165:address = "0.0.0.0:9090"
        app.toml:178:address = "0.0.0.0:9091"
        client.toml:15:node = "tcp://localhost:26657"
        config.toml:15:proxy_app = "tcp://127.0.0.1:26658"
        config.toml:91:laddr = "tcp://127.0.0.1:26657"
        config.toml:194:pprof_laddr = "localhost:6060"
        config.toml:202:laddr = "tcp://0.0.0.0:26656"
        config.toml:208:# example: 159.89.10.97:26656
        config.toml:419:prometheus_listen_addr = ":26660"
        root@vmi843831:~/seid2/config#
  
  Như kết quả thực hiện trên có thể thấy
   - Trường đầu tiên trước dấu hai chấm là tên file cần đổi, ví dụ **app.toml**
   - Trường thứ 2 là dòng trong file cần thực thiện đổi port, ví dụ dòng **114** của file **app.toml**
   - Trường thứ 3 là port cần đổi, ví dụ **tcp://0.0.0.0:1317** thì port cần đổi là **1317**
   - Giả sử nếu máy có cài nhiều VM của Commos thì nên quy hoạch port cần đổi của VM đó để tránh xung đột vs VM cũ và cả VM mới (nếu spam). Như ví dụ trên, có thể đổi port 266xx của VM-2 thành 267xx, 909x thành 929x, 606x => 626x. Tùy nhưng đừng xung đột.
   - Sau khi đã quy hoạch xong, thực hiện đổi port trong các file, giả sử là **app.toml**
          
          vi app.toml      
      Gõ **:set nu** thì file sẽ hiện lên thứ tự dòng, tìm tới dòng cần đổi và đổi port. Đổi xong cả thì save và thoát file. Tương tự thực hiện cho các file còn lại
 
  Thực hiện chạy node để kiểm tra, nếu có xung đột port thì tiến trình sẽ dừng lại, mình stop tiến trình và tìm xem port xung đột nằm đâu như bước 2.2.2. Giả sử ở bước 2.2.1 đã nhập SEI-ID là **seid2**, thì hệ thống tạo ra **seid2.service** tương ứng
  
          systemctl restart seid2.service 

**2.3 Tạo ví và tạo validator**

Giả sử ở bước 2.2.1 đã nhập SEI-ID là **seid2**, vậy thư mục cài đặt sẽ là /root/seid2, thực hiện tạo ví, sau đó xin faucet ở discord
        export SEI_PATH="$HOME/seid2"
        seid2 keys add YOUR_WALLET_NAME --home $SEI_PATH
        
Sau khi xin faucet thì tạo validator thứ 2 như sau

        seid2 tx staking create-validator \
        --amount=900000usei \
        --home $SEI_PATH \
        --pubkey=$(seid2 tendermint show-validator --home $SEI_PATH) \
        --moniker=YOUR_NODENAME \
        --chain-id=sei-testnet-2 \
        --commission-rate="0.10" \
        --commission-max-rate="0.20" \
        --commission-max-change-rate="0.01" \
        --min-self-delegation=1 \
        --from=YOUR_WALLET_NAME
        -y

**2.4 Kiểm tra trạng thái của các VM**

Tùy port tương ứng của VM mà sử dụng các lệnh sau

         curl -s localhost:26757/status | jq '.result."sync_info",.result."validator_info",.result."node_info"."network"'
