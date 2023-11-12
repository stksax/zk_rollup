pragma circom 2.1.5;
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";

template mux(){
    signal input in[2];
    signal input sel;
    signal output out[2];
    signal chose <== XOR()(sel, 1);
    (sel-1)*sel === 0;
    signal x <== chose*in[0];
    signal y <== chose*in[1];
    out[0] <== x + sel*in[1];
    out[1] <== y + sel*in[0];
}

template in_merkle_tree(n){
    signal input leaf;
    signal input route;
    signal input root;
    signal guide[n];
    guide <== Num2Bits(n)(route);
    signal input path_element[n];
    component hasher[n];
    signal ha[n];
    component mux[n];
    for (var i=0; i<n ;i++){
        mux[i]=mux();
        hasher[i]=Poseidon(2);
        if (i==0){
            mux[i].in[0] <== leaf;
            mux[i].in[1] <== path_element[i];
            mux[i].sel <== guide[i];
            hasher[i].inputs[0] <== mux[i].out[0];
            hasher[i].inputs[1] <== mux[i].out[1];
        }else{
            mux[i].in[0] <== hasher[i-1].out;
            mux[i].in[1] <== path_element[i];
            mux[i].sel <== guide[i];
            hasher[i].inputs[0] <== mux[i].out[0];
            hasher[i].inputs[1] <== mux[i].out[1];
        }
    }
    signal output out <== IsEqual()([root, hasher[n-1].out]);
    // root === hasher[n-1].out[0];
}