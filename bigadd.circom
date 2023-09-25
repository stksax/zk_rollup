pragma circom 2.1.5;
include "circomlib/bitify.circom";

template split(w){
    signal input in;
    signal output out <-- in%(1<<w);
    signal output carry <-- in\(1<<w);
    carry*(1<<w)+out === in;
    _ <== Num2Bits(w)(out);
}

template carryarr(n,w){
    signal input in[n];
    var i;
    signal output out[n+1];
    component split[n];
    for (i=0;i<n;i++)
        split[i]=split(w);

    split[0].in <== in[0];
    split[1].in <== split[0].carry + in[1];
    
    for (i=2;i<n;i++)
        split[i].in <== split[i-1].carry + in[i];
    
    for (i=0;i<n;i++)
        out[i] <== split[i].out;

    out[n] <== split[n-1].carry;
}
template addwithcarrymod2w(n,w){
    signal input a[n];
    signal input b[n];
    signal a2[n+1] <== carryarr(n,w)(a);
    signal b2[n+1] <== carryarr(n,w)(b);
    signal ab[n+1];
    var i;
    for (i=0;i<n+1;i++)
        ab[i] <== a2[i] + b2[i];
    signal output out[n+2] <== carryarr(n+1,w)(ab);
}
