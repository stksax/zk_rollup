pragma circom 2.1.5;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "keccak.circom";
include "babyjub_caculate.circom";
include "merkle_tree.circom";

template pay(merkle_tree_layer,n){
    //in merkle tree
    signal input private_key;
    signal input balance;
    //leaf[1] <== Keccak(2,1)([private_key,balance]);
    signal input route;
    signal input root;
    signal input pathelement[merkle_tree_layer];
    component in_merkle_tree=in_merkle_tree(merkle_tree_layer);
    in_merkle_tree.private_key <== private_key;
    in_merkle_tree.balance <== balance;
    in_merkle_tree.route <== route;
    in_merkle_tree.root <== root;
    in_merkle_tree.pathelement <== pathelement;

    //balance is enough to pay and generate new leaf
    signal input payment_in;
    signal output payment <== payment_in;
    signal check <== LessThan(252)([payment,balance]);
    check === 1;
    signal new_balance <== balance-payment;
    signal output new_leaf[1] <== Keccak(2,1)([private_key,new_balance]);

    //make the signature from making commitment, response
    component sign=sign(n);
    signal input reciver_public_key_x;
    signal input reciver_public_key_y;
    signal input random_num;
    sign.private_key <== private_key;
    sign.random_num <== random_num;
    sign.reciver_public_key_x <== reciver_public_key_x;
    sign.reciver_public_key_y <== reciver_public_key_y;
    sign.payment <== payment;
    signal output commitment_x <== sign.commitment_x;
    signal output commitment_y <== sign.commitment_y;
    signal output public_key_x <== sign.public_key_x;
    signal output public_key_y <== sign.public_key_y;
    signal output response <== sign.response;
}

template reciver_collect_payment(merkle_tree_layer,n){
    //in merkle tree
    signal input private_key;
    signal input old_balance;
   // leaf <== Keccak(2,1)([private_key,old_balance]);
    signal input route;
    signal input root;
    signal input pathelement[merkle_tree_layer];
    component in_merkle_tree=in_merkle_tree(merkle_tree_layer);
    in_merkle_tree.private_key <== private_key;
    in_merkle_tree.balance <== old_balance;
    in_merkle_tree.route <== route;
    in_merkle_tree.root <== root;
    in_merkle_tree.pathelement <== pathelement;

    signal input payment;
    signal input response;
    signal input sender_public_key_x;
    signal input sender_public_key_y;
    signal (diffie_hellman_key_x, diffie_hellman_key_y) <== point_times(n)(private_key, sender_public_key_x, sender_public_key_y);
    signal input commitment_x;
    signal input commitment_y;
    signal challenge[1] <== Keccak(5,1)([diffie_hellman_key_x, diffie_hellman_key_y, commitment_x, commitment_y, payment]);
    signal (check1_x,check1_y) <== calculate_point(n)(response);
    signal (check2_x,check2_y) <== point_times(n)(challenge[0],sender_public_key_x, sender_public_key_y);
    signal (check3_x,check3_y) <== BabyAdd()(commitment_x, commitment_y, check2_x, check2_y);
    check3_x === check1_x;
    check3_y === check1_y; 

    signal new_balance <== old_balance + payment;
    signal output new_leaf[1] <== Keccak(2,1)([private_key,new_balance]);
}

template withdraw(merkle_tree_layer){
    //in merkle tree
    signal input private_key;
    signal input balance;
    signal input pathelement[merkle_tree_layer];
    // leaf <== Keccak(2,1)([private_key,balance]);
    signal input route;
    signal input root;
    component in_merkle_tree=in_merkle_tree(merkle_tree_layer);
    in_merkle_tree.private_key <== private_key;
    in_merkle_tree.pathelement <== pathelement;
    in_merkle_tree.balance <== balance;
    in_merkle_tree.route <== route;
    in_merkle_tree.root <== root;

    //balance is enough to pay and generate new leaf
    signal input payment;
    signal output withdraw <== payment;
    signal check <== LessThan(252)([withdraw,balance]);
    check === 1;
    signal new_balance <== balance-withdraw;
    signal output new_leaf[1] <== Keccak(2,1)([private_key,new_balance]);
}