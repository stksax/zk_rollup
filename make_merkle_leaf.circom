pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/poseidon.circom";

template make_leaf(n){
    signal input pubkey[n];
    signal input balance[n];
    signal output leaf[n];
    for (var i=0;i<n;i++)
        leaf[i] <== Poseidon(2)([pubkey[i], balance[i]]);
}

component main=make_leaf(3);