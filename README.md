# NFT-auto-selling machine
checking wallet for payment - send token or fund back a mistaken payment

The auto-nft-saler.sh file is created to automate selling NFT.
Important Info : to sell Tokens based on payment you need to run a "relay node". Additionally, you don't need to open the port used for the node in your firewall.

In the future I will add extra functions to mint NFT and send the new Token directly to the sender of the amount of ADA.

# What exactly does this script?
First of all, you define a myAddr, priceoftoken, myToken, amountToSendUser.
The script runs and check if it finds a new transaction (TxHas). 
for every new TxHash, we have 2 cases. 
1. the sender for this TxHash is unknown, in this case either she / he sent the correnct amount of ADA (priceoftoken) and then we send her / him back the NFT (myToken) or she / he send wrong amount of ADA and we send her / him back the amount of ADA we have received (in this case, they receive their ADA but loosing only the fee for the last transaction)
2. the sender for this TxHash is myAddr, we do nothing and we add the TxHash in our file with old TxHashes.

# Requirements
To use this software you will need:
•	A fully synced Cardano node using version 1.33.0
•	A Linux (tested on Ubuntu) system
•	Basic knowledge of Cardano-CLI commands 
•	A Blockfrost mainnet account and project ID (API key).

# Installation
Step 1 - Download the script
To get started with the system it is first necessary to download the files.

    git clone https://github.com/hubthom/NFT-auto-selling.git


Step 2 - modify variables
We need to update a few things in auto-nft-saler.sh before we can set it running:
cd ..
nano auto-nft-saler.sh
Firstly on lines 9,10,12 we need to add the payment address (i hope you have one), as well as add the paths to the payment and policy skey files and the price of Token we sell.

For example: (lines 9,10)
myAddr=addr1qyyhy.....
paymentSignKeyPath=/opt/cardano/cnode/priv/wallet/Vsales/payment.skey
and last parameter to change how much your NFTs cost (line 12)
priceoftoken=3000000

Now we need to add the Blockfrost project ID on lines 81 where it currently says 'Insert here'.
Next change the value of amountToSendUser on line 129 to your price in lovelace. This accounts for the 1.85 ADA sent back to the user.

Step 3 - Create a systemctl process
In order for the system to run 24/7 we need to create a systemd service:
sudo nano /etc/systemd/system/nftsales.service
Now paste the following into the text editor:
[Unit]
Description=NFT Vending Machine

[Service]
Environment="CARDANO_NODE_SOCKET_PATH=/opt/cardano/cnode/sockets/node0.socket"
ExecStart=/usr/bin/auto-nft-saler.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target

Save and exit the file and then type:
sudo cp auto-nft-saler.sh /usr/bin/nftsales.sh


Before this will work we need to make sure cardano-cli and cardano-node are in system directories. The Guild setup puts those programs in your home folder which won't work for a systemd service.
Thankfully this is easy to fix with two commands:
sudo cp ~/.cabal/bin/cardano-cli /usr/bin/cardano-cli
sudo cp ~/.cabal/bin/cardano-node /usr/bin/cardano-node


Next we need to start and enable the service:
sudo systemctl enable nftsales.service
sudo systemctl start nftsales.service


Check the service is working by typing:
sudo systemctl status vendingmachine.service

It should show no errors and you're all set.

You can also check the log file :
cat log_file.txt

If all is working as it should, you should see logs of past transactions. For this current moment i have many logs, so that we see better the whole process.
After testing, you can remove many of them so that you keep less logs in your file.
You are now set up to automatically sell and distribute your NFTs!
