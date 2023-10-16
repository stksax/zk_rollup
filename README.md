# zk_rollup
this circom project can do the transaction without let the bank knows your private key and packing several transaction to generate a new merkle tree root that contain all the transactions inside. It's the idea about zero knowledge proof, user can withdraw money, pay money to someone, and receive money from others. And each part they have to use their private key, so it's undeniable after doing the transaction.

# how to do the transaction
It can do three kinds of transactions: pay to someone, withdraw, and receive. If you want to pay money to someone, you have to enter your private key and balance for proving your account is in merkle tree(this make the transaction undeniable for you and bank), check payment is less than balance, and use your public key and a random number to do a sigma protocol, and it contain Diffie–Hellman key exchange inside, so your payment is undeniable to receiver(because he have to use your public key to generate Diffie–Hellman key, and use Diffie–Hellman key to solve sigma protocol). When we talk about withdraw, that is almost the same as pay, but you don't have to make the sigma protocol. As a receiver, beside proof your account is in merkle tree as before, you have to use your private key and sender's public key for making Diffie–Hellman key, in order to verify who pay money to you and how much, so the identity of two traders and the payment are clear, after you do any transcation, you should update merkle leaf. 
Finally we will collect all the transactions to create a new merkle root.

## babyjub_calculate
I use babyjub to generate public key because that is friendly to circom. In making signature, it contain the classic sigma protocol, but I add Diffie–Hellman key exchange in that(when generating challenge). 
<img src="instructions.png" alt="png">

## keccak256 
that is hasher for merkle tree and making challenge, of course it can be changed to sha256 or others

## merkle tree 
merkle tree's leaf is for private key and balance do the hash, it contain prevent double spend (there will not be two same leaf in the same time),and collecting all the new leafs to generate a new root to finish rollup.

