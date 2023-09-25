pragma circom 2.1.5;
include "circomlib/circuits/gates.circom";
include "circomlib/circuits/bitify.circom";
include "keccak.circom";

template mul(){
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

template merkle_tree(n){
    signal input leaf;
    signal input route;
    signal input root;
    signal guide[n];
    guide <== Num2Bits(n)(route);
    signal input pathelement[n];
    component hasher[n];
    signal ha[n];
    component mul[n];
    for (var i=0; i<n ;i++){
        mul[i]=mul();
        hasher[i]=Keccak(2, 1);
        if (i==0){
            mul[i].in[0] <== leaf;
            mul[i].in[1] <== pathelement[i];
            mul[i].sel <== guide[i];
            hasher[i].in[0] <== mul[i].out[0];
            hasher[i].in[1] <== mul[i].out[1];
        }else{
            mul[i].in[0] <== hasher[i-1].out[0];
            mul[i].in[1] <== pathelement[i];
            mul[i].sel <== guide[i];
            hasher[i].in[0] <== mul[i].out[0];
            hasher[i].in[1] <== mul[i].out[1];
        }
    }
    root === hasher[n-1].out[0];
}
