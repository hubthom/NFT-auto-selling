#!/bin/bash

cd /home/cardano/git/thomas/
looping=1
log=/home/cardano/git/thomas/log_file.txt
txs=/home/cardano/git/thomas/txs.txt
txsin=/home/cardano/git/thomas/txsin.txt
fullUtxo=/home/cardano/git/thomas/fullUtxo.out
balance=/home/cardano/git/thomas/balance.out
utxojason=/home/cardano/git/thomas/utxo.json
txtmp=/home/cardano/git/thomas/tx.tmp
txraw=/home/cardano/git/thomas/tx.raw
txsigned=/home/cardano/git/thomas/tx.signed
protocoljson=/home/cardano/git/thomas/protocol.json
txdraft=/home/cardano/git/thomas/tx.draft
tipjson=/home/cardano/git/thomas/tip.json
numberCompleted=0
donAddr=addr1q9adpgxj4lv6z8qwvdculct4gf3ue4s6323jyd0565q4524uppuskx0yl75rat65kw0vr5g34gpve9agzm2nkm7se7qd0r
myAddr=addr1q9adpgxj4lv6z8qwvdculct4gf3ue4s6323jyd0565q4524uppuskx0yl75rat65kw0vr5g34gpve9agzm2nkm7se7qd0r
paymentSignKeyPath=/opt/cardano/cnode/priv/wallet/wallet_name/payment.skey
profitAddr=addr1
priceoftoken=3000000
tokenAmountFinal=-1
myInitADA=-1
my_tx_in=-1
my_old_tx_in=-2
transSending=0
myToken=0fd9819a9d7fb423553f43a42d33679858f12bc5f9441cec643dc15.56693462453
sender=/home/cardano/git/folder/sender.txt
echo "" >> $txs
echo "" >> $txsin
echo "" >> $utxojason
echo "" >> $log
echo "Log File" >> $log
echo "-------------------" >> $log
echo "Process started at: $(date +%T)" >> $log
echo "-------------------" >> $log
echo "" >> $log

trap 'looping=0;wait' INT TERM

while (( looping )); do
    sleep 1m
    echo "entering quering UTxO Look"
    echo "entering quering UTxO Look" >> $log
    cardano-cli query utxo --address $myAddr --mainnet > $fullUtxo
    tail -n +3 ${fullUtxo} | sort -k3 -nr  > $balance
    cat ${balance}
    while read -r utxo; do
        sleep 1m
        echo "UTXO detected"
        echo "UTXO detected" >> $log
        echo "original token Amount : ${originalTokenAmount}" >> $log
        tx_hash=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
        tx_in="${tx_hash}#${idx}"
        token=$(awk '{ print $7}' <<< "${utxo}")
        tokenAmount=$(awk '{ print $6}' <<< "${utxo}")
        txcnt=$(cat ${balance} | wc -l)
        if [[ ${token} = ${myToken} ]]
        then
            echo "myToken is detected"
            echo "myToken is detected" >> $log
            myInitADA=$(awk '{ print $3}' <<< "${utxo}")
            echo "myInitADA : ${myInitADA}" >> $log
            tokenAmountFinal=${tokenAmount}
            my_tx_in=${tx_in}
            if [[ ${my_tx_in} = ${my_old_tx_in} ]] && [[ ${transSending} -eq 1 ]];
            then
                echo "Sending TX in Progress"
                break
            else
                echo "new Tx detected"
                transSending=0
                my_old_tx_in=${my_tx_in}
            fi
        elif [ ${myInitADA} -eq -1 ];
        then
            echo "Initializing Original Values"
            echo "Initializing Original Values" >> $log
            continue
        else
            echo "myToken ISNOT detected"
            echo "myToken ISNOT detected" >> $log
        fi
        if [ ${transSending} -eq 1 ];
        then
            echo "Sending Transaction in Progress"
            break
        fi
        echo "TX_Hash : ${tx_hash}" >> $log
        echo "idx : ${idx}" >> $log
        echo "balance : ${utxo_balance}" >> $log
        echo "tx_in : ${tx_in}" >> $log
        echo "token : ${token}" >> $log
        echo "txcnt : ${txcnt}" >> $log
        echo "tokenAmount : ${tokenAmount}" >> $log
        echo "tokenAmountFinal : ${tokenAmountFinal}" >> $log
        echo "my_tx_in : ${my_tx_in}" >> $log
        if [ $( grep -q "${tx_in}" "$txsin" && echo $? ) ]
        then
            echo "OLD tx is Detected..."
            echo "OLD tx is Detected..." >> $log
            continue
        else
            echo "New tx is Detected..."
            echo "New tx is Detected..." >> $log
            echo ${tx_in} >> $txsin
            in_addr=$(curl -H 'project_id: mainnetb223DFG435FuHTTWog48i8SEhuWhEegfA' \
                    https://cardano-mainnet.blockfrost.io/api/v0/txs/${tx_hash}/utxos \
                    | jq '.inputs' | jq '.[0]' | jq '.address' | sed 's/^.//;s/.$//')
            echo "1. Sender_Address : ${in_addr}" >> $log
            if [[ ${utxo_balance} != $priceoftoken ]] && [[ ${in_addr} != ${myAddr} ]];
            then
                echo "Send back : ${utxo_balance}" >> $log
                echo "Refund Initiated..." >> $log
                echo "Refund Initiated..."
                currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
                cardano-cli transaction build-raw \
                    --fee 200000 \
                    --tx-in ${tx_in} \
                    --tx-out ${in_addr}+${utxo_balance} \
                    --invalid-hereafter $(( ${currentSlot} + 2000)) \
                    --out-file ${txtmp} >> $log
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file ${txtmp} \
                    --tx-in-count 1 \
                    --tx-out-count 1 \
                    --mainnet \
                    --witness-count 1 \
                    --byron-witness-count 0 \
                    --protocol-params-file ${protocoljson} | awk '{ print $1 }') >> $log
              fee=${fee%" Lovelace"}
                amountToSendUser=$(( ${utxo_balance}-${fee} ))
                echo "Send Without Fee : ${amountToSendUser}" >> $log
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                    --tx-in ${tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser} \
                    --invalid-hereafter $(( ${currentSlot} + 1000)) \
                    --out-file ${txraw} >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
                    --tx-body-file ${txraw} \
                    --out-file ${txsigned} \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file ${txsigned} --mainnet >> $log
                echo "Refund is Sent"
                myInitADA=-1
                transSending=1
            elif [ ${in_addr} = ${myAddr} ]
            then
                echo "my Address is detected"
                continue
            else
                echo "Sending NFT..."
                echo "Sending NFT..." >> $log
                echo "New Sender_Address : ${in_addr}" >> $sender
                numberCompleted=$(( numberCompleted+1 ))
                amountToSendUser=1850000
                currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
                # get utxo
                echo "Getting utxo"
                cardano-cli query utxo \
                    --address ${myAddr} \
                    --mainnet \
                    --out-file ${utxojason}
                echo "utxo done"
                # transaction variables
                TXNS=$(jq length ${utxojason})
                echo "TXNS : ${TXNS}" >> $log
                # Next tip before no transaction
                echo "Getting chain tip"
                cardano-cli query tip --mainnet --out-file ${tipjson}
                TIP=$(jq .slot ${tipjson})
                DELTA=2000
                FINALTIP=$(( ${DELTA} + ${TIP} ))
                echo $FINALTIP >> $log
                echo "Building Draft Transaction" >> $log
                cardano-cli transaction build-raw \
                    --fee 0 \
                    --tx-in ${tx_in} \
                    --tx-in ${my_tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"20000000 ${myToken}" \
                    --tx-out ${myAddr}+${myInitADA}+"${tokenAmountFinal} ${myToken}" \
                    --invalid-hereafter $FINALTIP \
                    --out-file ${txdraft}
                echo "Draft Transaction is Done" >> $log
                echo "Calculating Transaction Fee"
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file ${txdraft} \
                    --tx-in-count 2 \
                    --tx-out-count 2 \
                    --witness-count 1 \
                    --mainnet \
                    --protocol-params-file ${protocoljson} \
                    | tr -dc '0-9')
                echo "fee : ${fee}" >> $log
                aDAToReturn=$(expr $priceoftoken - $amountToSendUser - $fee + $myInitADA)
                echo "aDAtToReturn : ${aDAToReturn}" >> $log 
                echo "amountToSendUser : ${amountToSendUser}" >> $log
                tokenToKeep=$(expr $tokenAmountFinal - 20000000)
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                    --tx-in ${tx_in} \
                    --tx-in ${my_tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"20000000 ${myToken}" \
                    --tx-out ${myAddr}+${aDAToReturn}+"${tokenToKeep} ${myToken}" \
                    --invalid-hereafter $FINALTIP \
                    --out-file ${txraw} >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
                    --tx-body-file ${txraw} \
                    --out-file ${txsigned} \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file tx.signed --mainnet >> $log
                myInitADA=-1
                transSending=1
            fi
        fi
    done < ${balance}
    wait
done
