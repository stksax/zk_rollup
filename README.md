# zk_rollup
ecdsa in the cruve sepc256k, and the result sould in the merkle tree, it contains four parts:ecdsa,bigint,keccak,merkletree
it used for verify the point(x,y) is in sepc256k1 cruve, key*g=(x,y) , g means the base point (g=x252[0],y252[0])
if key is given, it can be verify in 252 round of count (key is in range of 1~2**252)
first we check x252 and y252 is correct 
and change the key to binary, so it can be 2**a + 2**b + 2**c 
path means every step we verify, if key = [1,0,1,1], path=[1,1,5,13], path[n-1] == x,y
because circom have limit on counting (limit around 2**252), so i had writted bigint counting(bigadd, muilt, sud)
number had been mod with 2**126, so it will not be more than 2**252 if we muilt
and after we verify the point we can verify if it is in merkle tree,and merkle tree's hasher i used keccak256

這是用sepc256k這條橢圓曲線做的數字簽名，key 作為私鑰,(x,y)為key*g (g=基準點), 輸入2^(0~252) * g的點, 並驗證他在曲線上且x[i-1] + x[i-1] =x[i]
輸入x252,y252並驗證他是2^(0~252)*g的點
把key轉為2進制，key=2**a+2**b+2**c,所以計算出key**g不會超過252次(key<2**252)
path表示驗證中的計算過程,若key=13,二進制為[1,0,1,1], path=[1*g,1*g,5*g,13*g], path的最後一項為(x,y)=key*g
因為circom有計算的上限(大約在2**252), 所以我做了大數運算的程式，並把他mod2**126，因此相乘時不會超過2**252
完成後可以用檢視他是否在merkletree裡，而merkletree的hash我選擇keccak256
# bigint
because the cauculate limit on circom is around 2^252, so i mod the number with 2^126, so even muilt two number will not be more than 2^252. The number will be like [1,2,3,0], it means 1+2*(2^252)+3*(2^252)^2.

#keccak256
that is hasher for merkle tree and digital envelope

#merkle tree 
It's a useful function for rollup the signature , if someone wants to proof his signature is one of the leaf of tree, beside the leaf, he needs to provide three things
1. guide number(it will be change to binary to show the leaf and the father is on left or right)
2. path element (the brothers in the tree)
3. root

#ecdsa
