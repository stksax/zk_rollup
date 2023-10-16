# zk_rollup
this circom project can do the transaction without let the bank knows your private key and packing serveal transcation to generate a new merkle tree root that contain all the transactions inside. It's the idea about zero knowledge proof, user can withdraw money, pay money to someone, and recive money from others. And each part they have to use their private key, so it's undeniable after doing the transcation.

# how to do the transcation
It can do three kinds of transactions: pay to someone, withdraw,and recive. If you want to pay money to someone, you have to enter your private key and balance for proving your account is in merkle tree(this make the transaction undeniable for you and bank), check payment is lessthan blance, and use your public key and a random number to do a sigma protocol, and it contain Diffie–Hellman key exchange inside, so your payment is undeniable to reciver(because he have to use your public key to generate Diffie–Hellman key, and use Diffie–Hellman key to solve sigma protocol). When we talk about withdraw, that is almost the same as pay, but you don't have to make the sigma protocol. As a reciver, beside proof your account is in merkle tree as before, you have to use your private key and sender's public key for making Diffie–Hellman key, inorder to verify who pay money to you and how much, so the identity of two traders and the payment are clear, after you do any transcation, you should update merkle leaf. 
Finially we will collect all the transcations to creat a new merkle root.

## babyjub_caculate
I use babyjub to generate public key because that is friendly to circom.In making signature, it contain the classic sigma protocol, but I add Diffie–Hellman key exchange in that(when generating challenge). 
<img src="instructions.png" alt="png">

## keccak256 
that is hasher for merkle tree and makeing challenge, of course it can be changed to sha256 or others

## merkle tree 
merkle tree's leaf is for private key and balance do the hash, it contain prevent double spend (there will not be two smae leaf in the same time),and collecting all the new leafs to generate a new root to finish rollup.



