# zk_rollup
this circom project can do the transaction without let others knows your private key and packing several transaction to generate new merkle tree leaf that contain user public key and current balance. It's the idea about zero knowledge proof, user can withdraw money, pay money to someone, and receive money from others.

# how the transaction work
If user wants to trade, he need to enter his public key ,a message ,public key and message will be use for generate random number and his signature (I chose eddsaposeidon for verify the four thing).The message contain what kind of trade he want to do (withdraw, pay, save), your account's location in merkle tree and balance , how much you want to pay, and who will receive the payment. And it will generate two list, who get the money and who spend it, if all information is correct, the pay ment will be add inside, if is invalid, the payment will show zero.`s`

# test
I wrote two test, one is simulation all the situaction can happen in trade, the other (test2) is use the two list(receipt of transcation) to generate new leaf of merkle tree. The first one contain normal trade, someone enter the wrong information, doing transcation without enough balance, someone want to cheat about his account balance, withdraw and save money.The second test I input the reciept list that was made in the last test, and check if the leaf is as our expect. 

## keccak256 
that is hasher for merkle tree and making challenge, of course it can be changed to sha256 or others

## merkle tree 
merkle tree's leaf is for private key and balance do the hash, it contain prevent double spend (there will not be two same leaf in the same time),and collecting all the new leafs to generate a new root to finish rollup.

