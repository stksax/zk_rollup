# zk_rollup
gas fee too high is always a problem in ethereum, if we want to make ethereum decentralization, security and scalability. Zero knpwledge proof is the selution to that, so I made this project. This circom project can verify eddsa signature and pack them into a merkle tree root in UTXO way (Unspent Transaction* Output), so the gas fee can be reduce.

# how the transaction work
If user wants to trade, he need to enter his public key ,a message ,public key and message will be use for generate random number and his signature (I chose eddsaposeidon for verify the four thing).The message contain what kind of trade he want to do (withdraw, pay, save), your account's location in merkle tree and balance , how much you want to pay, and who will receive the payment. And it will generate two list, who get the money and who spend it, if all information is correct, the payment will be add inside, if is invalid, the payment will show zero.  

Detail in `zk_rollup.circom`

# test1
this test is for verify the signature, and generate a UTXO result (Unspent Transaction* Output), that contain the sender's balance after transaction, and transfer for reciever, if balance isn't enough or someone forgery, the transcation will not success  
I simulation all the situation can happen in trade, transfer to other, deposie, withdraw, and if someone transfer without enough balance 
  
run `mocha -p -r ts-node/register 'test1.js'`

# test2
after we do the test1, we got a list that record the sender balance left, and the transfer reciever get, then we take the two list to generate a new merkle tree root to finish rollup, I also calaulate the new merkle tree leaf in another way to see if the result is as my expect, but it doenn't exsist in the real project.
  
run `mocha -p -r ts-node/register 'test2.js'`

## merkle tree 
merkle tree's leaf can generate a root that contain all the account and it's balance inside, merkle tree's leaf is generate from public key and balance, I use poseidon to do the hash, so we just need to give the location of account, his bother leaf, root. We can know is it correct or not in a fast way.

