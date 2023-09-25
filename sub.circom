pragma circom 2.1.5;
include "circomlib/comparators.circom";
include "circomlib/gates.circom";
template modsub(w){
    signal input a;
    signal input b;
    signal neg <== LessThan(w)([a,b]);
    signal output out <== a - b + neg * (1<<w);
}

template modsubthree(w){
    signal input a;
    signal input b;
    signal input c;
    signal output neg <== LessThan(w)([a,b+c]);
    signal output out <== a - b - c + neg * (1<<w);
}
template arrsub(n,w){
    signal input a[n];
    signal input b[n];
    component modsubthree[n];
    signal output out[n];
    for (var i=0;i<n;i++){
        modsubthree[i] = modsubthree(w);
        modsubthree[i].a <== a[i];
        modsubthree[i].b <== b[i];
        if (i==0){
            modsubthree[i].c <== 0;
        }else{
            modsubthree[i].c <== modsubthree[i-1].neg;
        }
        out[i] <== modsubthree[i].out;
    }
}
