pragma circom 2.1.5;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
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

template in_merkle_tree(n){
    signal input private_key;
    signal input balance;
    signal leaf[1] <== Keccak(2, 1)([private_key,balance]);
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
            mul[i].in[0] <== leaf[0];
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
//not yet
template update_merkle_tree(n){
    signal input new_leaf[n];
    signal node[n-1];
    var counter=0;
    component Keccak[n-1];
    for (var i=0;i<n-1;i++){
        Keccak[i]=Keccak(2,1);
        if (i<n/2){
            Keccak[i].in[0] <== new_leaf[2*i];
            Keccak[i].in[1] <== new_leaf[2*i+1];
            node[i] <== Keccak[i].out[0];
            counter+=1;
        }else{
            Keccak[i].in[0] <== node[(i-counter)*2];
            Keccak[i].in[1] <== node[(i-counter)*2+1];
            node[i] <== Keccak[i].out[0];
        }
    }
    signal output root <== node[n-2];
}

template prevent_double_spend(n){
    signal input leaf[n];
    var unequalcheck=0;
    component IsEqual[n*n];
    for (var i=0;i<n;i++){
        for (var j=0;j<n;j++){
            IsEqual[i*n+j]=IsEqual();
            IsEqual[i*n+j].in[0] <== leaf[i];
            IsEqual[i*n+j].in[1] <== leaf[j];
            unequalcheck += IsEqual[i].out;
        }
    }
    signal check <== unequalcheck;
    check === n;
    signal output new_leaf[n];
    for(var i=0;i<n;i++)
        new_leaf[i] <== leaf[i];
}

template rollup(n){
    signal input leaf[n];
    component prevent_double_spend = prevent_double_spend(n);
    for (var i=0;i<n;i++)
        prevent_double_spend.leaf[i] <== leaf[i];

    signal output root <== update_merkle_tree(n)(leaf);
}