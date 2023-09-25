pragma circom 2.0.2;

include "circomlib/gates.circom";
include "circomlib/sha256/xor3.circom";
include "circomlib/sha256/shift.circom";

template XorArray(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];

    for (var i=0;i<n;i++){
        out[i]<==XOR()(a[i],b[i]);
    }
}

template XorArrayInverse(n) {
    signal input in[n];
    signal output out[n];
    var one[n],i;

    for (i=0; i<n; i++) {
        one[i]=1;
    }
    out<==XorArray(n)(in,one);
}

template OrArray(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];

    for (var i=0;i<n;i++){
        out[i]<==OR()(a[i],b[i]);
    }
}

template AndArray(n) {
    signal input a[n];
    signal input b[n];
    signal output out[n];

    for (var i=0;i<n;i++){
        out[i]<==AND()(a[i],b[i]);
    }
}

template Xor5(n) {
    signal input in1[n];
    signal input in2[n];
    signal input in3[n];
    signal in123[n];
    signal input in4[n];
    signal in1234[n];
    signal input in5[n];
    signal output out[n];
    
    in123<==Xor3(n)(in1,in2,in3);
    in1234<==XorArray(n)(in123,in4);
    out<==XorArray(n)(in1234,in5);
}


template ShL(n, r) {
    signal input in[n];
    signal output out[n];

    for (var i=0; i<n; i++) {
        if (i < r) {
            out[i] <== 0;
        } else {
            out[i] <== in[ i-r ];
        }
    }
}
