pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/poseidon.circom";

template circuit(){
    signal input in[7];
    signal output out <== Poseidon(7)([in[0], in[1], in[2], in[3], in[4], in[5], in[6]]);
}

component main=circuit();