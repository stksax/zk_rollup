# zk_rollup
gas fee too high is always a problem in ethereum, if we want to make ethereum decentralization, security and scalability. Zero knpwledge proof is the selution to that, so I made this project. This circom project can verify eddsa signature and pack them into a merkle tree root in UTXO way (Unspent Transaction* Output), so the gas fee can be reduce.

# how the transaction work
If user wants to trade, he need to enter his public key ,a message ,public key and message will be use for generate random number and his signature (I chose eddsaposeidon for verify the four thing).The message contain what kind of trade he want to do (withdraw, pay, save), your account's location in merkle tree and balance , how much you want to pay, and who will receive the payment. And it will generate two list, who get the money and who spend it, if all information is correct, the payment will be add inside, if is invalid, the payment will show zero.

Detail in `zk_rollup.circom`

# test1
this test is for verify the signature, and generate a UTXO result (Unspent Transaction* Output), that contain the sender's balance after transaction, and transfer for reciever, if 
I wrote two test, one is simulation all the situation can happen in trade, the other (test2) is use the two list(receipt of transaction) to generate new leaf of merkle tree. The first one contain normal trade, someone enter the wrong information, doing transaction without enough balance, someone want to cheat about his account balance, withdraw and save money.The second test I input the receipt list that was made in the last test, and check if the leaf is as our expect. 

## merkle tree 
merkle tree's leaf is from public key and balance do the hash, I use poseidon to do the hash 

