##!/bin/bash

cd /home/$(whoami)/git/thomas
rm log_file.txt
looping=1
log=log_file.txt
txs=txs.txt
numberCompleted=0
myAddr=addr1qyyhymjpwn23874jfu04989ufkjgfolijfldfjow9580584058024820rwoehfe98gf7b87b97969676869dgt0e84z440lt0grvysse3fyck
paymentSignKeyPath=/opt/cardano/cnode/priv/wallet/Vsales/payment.skey
profitAddr=addr1
priceoftoken=3000000
tokenAmountFinal=-1
myInitADA=-1
my_tx_in=-1
myToken=0fd9883479f0g8475hefu98432098gje8378457648239fjr4097823409feg57dc15.563456353
echo "" >> $txs
echo "" >> $log
echo "Log File" >> $log
echo "-------------------" >> $log
echo "Process started at: $(date +%T)" >> $log
echo "-------------------" >> $log
echo "" >> $log

trap 'looping=0;wait' INT TERM

while (( looping )); do
    echo "entering quering UTxO Look"
    echo "entering quering UTxO Look" >> $log
    cardano-cli query utxo --address $myAddr --mainnet > fullUtxo.out
    tail -n +3 fullUtxo.out | sort -k3 -nr  > balance.out
    cat balance.out
    while read -r utxo; do
        sleep 5s
        echo "UTXO detected"
        echo "UTXO detected" >> $log
        echo "original token Amount : ${originalTokenAmount}" >> $log
        tx_hash=$(awk '{ print $1 }' <<< "${utxo}")
        idx=$(awk '{ print $2 }' <<< "${utxo}")
        utxo_balance=$(awk '{ print $3 }' <<< "${utxo}")
        tx_in="${tx_hash}#${idx}"
        token=$(awk '{ print $7}' <<< "${utxo}")
        tokenAmount=$(awk '{ print $6}' <<< "${utxo}")
        txcnt=$(cat balance.out | wc -l)
        if [[ ${token} = ${myToken} ]]
        then
                echo "myToken is detected"
                echo "myToken is detected" >> $log
                myInitADA=$(awk '{ print $3}' <<< "${utxo}")
                echo "myInitADA : ${myInitADA}" >> $log
                tokenAmountFinal=${tokenAmount}
                my_tx_in=${tx_in}
        elif [[ ${myInitADA} -eq -1 ]]
        then
                echo "Initializing Original Values" 
                echo "Initializing Original Values" >> $log
                continue
        else
                echo "myToken ISNOT detected" 
                echo "myToken ISNOT detected" >> $log
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
        echo "cat ${txs}"
        if [ $( grep -q "${tx_hash}" "$txs" && echo $? ) ]
        then
            echo "OLD tx is Detected..."
            echo "OLD tx is Detected..." >> $log
            continue
        else
            echo "New tx is Detected..."
            echo "New tx is Detected..." >> $log
            echo ${tx_hash} >> $txs
            in_addr=$(curl -H 'project_id: Insert here' \
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
                    --out-file tx.tmp >> $log
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file tx.tmp \
                    --tx-in-count 1 \
                    --tx-out-count 1 \
                    --mainnet \
                    --witness-count 1 \
                    --byron-witness-count 0 \
                    --protocol-params-file protocol.json | awk '{ print $1 }') >> $log
              fee=${fee%" Lovelace"}
                amountToSendUser=$(( ${utxo_balance}-${fee} ))
                echo "Send Without Fee : ${amountToSendUser}" >> $log
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                    --tx-in ${tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser} \
                    --invalid-hereafter $(( ${currentSlot} + 1000)) \
                    --out-file tx.raw >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
                    --tx-body-file tx.raw \
                    --out-file tx.signed \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file tx.signed --mainnet >> $log
                echo "Refund is Sent"
            elif [ ${in_addr} = ${myAddr} ]
            then
                echo "my Address is detected"
                continue
            else
                echo "Sending NFT..."
                echo "Sending NFT..." >> $log
                numberCompleted=$(( numberCompleted+1 ))
                amountToSendUser=1850000
                currentSlot=$(cardano-cli query tip --mainnet | jq -r '.slot')
                # get utxo
                echo "Getting utxo"
                cardano-cli query utxo \
                    --cardano-mode \
                    --mainnet \
                    --address ${myAddr} \
                    --out-file utxo.json
                echo "utxo done"
                # transaction variables
                TXNS=$(jq length utxo.json)
                echo "TXNS : ${TXNS}" >> $log
                # Next tip before no transaction
                echo "Getting chain tip"
                cardano-cli query tip --mainnet --out-file tip.json
                TIP=$(jq .slot tip.json)
                DELTA=2000
                FINALTIP=$(( ${DELTA} + ${TIP} ))
                echo $FINALTIP >> $log
                echo "Building Draft Transaction" >> $log
                cardano-cli transaction build-raw \
                    --fee 0 \
                    --tx-in ${tx_in} \
                    --tx-in ${my_tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"2 ${myToken}" \
                    --tx-out ${myAddr}+${myInitADA}+"${tokenAmountFinal} ${myToken}" \
                    --invalid-hereafter $FINALTIP \
                    --out-file tx.draft
                echo "Draft Transaction is Done" >> $log
                echo "Calculating Transaction Fee"
                fee=$(cardano-cli transaction calculate-min-fee \
                    --tx-body-file tx.draft \
                    --tx-in-count 2 \
                    --tx-out-count 2 \
                    --witness-count 3 \
                    --mainnet \
                    --protocol-params-file protocol.json \
                    | tr -dc '0-9')
                echo "fee : ${fee}" >> $log
#                fee=200000
                aDAToReturn=$(expr $priceoftoken - $amountToSendUser - $fee + $myInitADA)
#                amountToReturn=$(expr $priceoftoken - $amountToSendUser)
#                amountToSendUserNew=$(expr $amountToSendUser - $fee)
                echo "aDAtToReturn : ${aDAToReturn}" >> $log 
                echo "amountToSendUser : ${amountToSendUser}" >> $log
                tokenToKeep=$(expr $tokenAmountFinal - 2)
                cardano-cli transaction build-raw \
                    --fee ${fee} \
                    --tx-in ${tx_in} \
                    --tx-in ${my_tx_in} \
                    --tx-out ${in_addr}+${amountToSendUser}+"2 ${myToken}" \
                    --tx-out ${myAddr}+${aDAToReturn}+"${tokenToKeep} ${myToken}" \
                    --invalid-hereafter $FINALTIP \
                    --out-file tx.raw >> $log
                cardano-cli transaction sign \
                    --signing-key-file $paymentSignKeyPath \
                    --tx-body-file tx.raw \
                    --out-file tx.signed \
                    --mainnet >> $log
                cardano-cli transaction submit --tx-file tx.signed --mainnet >> $log
            fi
        fi
    done < balance.out
    wait
done
