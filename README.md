# zk_rollup
this circom project can do the transaction without let the bank knows your private key and packing serveal transcation to generate a new merkle tree that contain all the transactions inside. It's the idea about zero knowledge proof, user can do withdraw money, pay money to someone, and recive money from others. And each part they have to use their private key, so it's undeniable after doing the transcation.

# babyjub_caculate
I use babyjub to generate public key because that is friendly to circom $$private key * generater = public key $$
# keccak256 
that is hasher for merkle tree and digital envelope

# merkle tree 
It's a useful function for rollup the signature , if someone wants to proof his signature is one of the leaf of tree, beside the leaf, he needs to provide three things
1. guide number(it will be change to binary to show the leaf and the father is on left or right)
2. path element (the brothers in the tree)
3. root

# ecdsa
It can verify someone owns the key of a point on cruve(sepc256k), you need to input the private key (private key * g = piblic key), public key, and 2^i (i from 0 to 252, and generator is 2^0), it can reduse the verification time from O(2^n) to O(n), if you know the key, first it change the private key to binary, because number can be a*2^0+b*2^1+c*2^2...., so we can verify it very soon

# digital envelope

