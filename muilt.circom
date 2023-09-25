pragma circom 2.1.5;
include "circomlib/bitify.circom";
include "circomlib/gates.circom";
include "circomlib/comparators.circom";
include "bigadd.circom";

template muilt(w){
    signal input a;
    signal input b;
    component split[3];
    for (var i=0;i<3;i++)
        split[i]=split(w);
    split[0].in <== a;
    signal a2 <== split[0].out;
    signal acarry <== split[0].carry;

    split[1].in <== b;
    signal b2 <== split[1].out;
    signal bcarry <== split[1].carry;

    signal ab <== a2 + b2;
    split[2].in <== ab;
    signal output out <== split[2].out;
    signal abcarry <== split[0].carry;
    signal output carry <== abcarry + acarry + bcarry;
}

template arrmuiltnocarry(x,y){
    signal input a[x];
    signal input b[y];
    var aval;
    var bval;
    var abval;
    var i;
    var j;
    signal output out[x+y-1];
    for (i=0;i<x+y-1;i++){
        abval=0;
        var start=0;
        if (i+1>y){
            start=i+1-y;
        }
        for (j=start;j<i+1 && j<x;j++){
            abval += a[j] * b[i-j];
        }
        out[i] <-- abval;
    }

    aval=0;
    bval=0;
    abval=0;
    for (i = 0; i < x; i++) {
        aval += 234 ** i * a[i];
        }
    for (i = 0; i < y; i++) {
        bval += 234 ** i * b[i];
    }
    for (i = 0; i < x+y-1; i++) {
        abval += 234 ** i * out[i];
    }
    aval * bval === abval;
}

template samearrmuiltnocarry(x){
    signal input a[x];
    signal input b[x];
    signal output out[2*x-1] <== arrmuiltnocarry(x,x)(a,b);
}


//把一組輸入轉成w**j,[1,2,3,4,5,6] ==> 1+2w+3w**2, 4+5w+6w**2，g為幾個一組
template regroup(w, n, g) {
    var newlen = (n-1)\g+1;
    signal input in[n];
    signal output out[newlen];
    var i,j,acc;    
    for (i=0;i<newlen;i++){
        acc=0;
        for (j=0;j<g && i*g+j<n;j++){
            acc+= w**j*in[i*g+j];
        }
        out[i] <== acc;
    }
}
//(2**126)*(2**126)<=2**252
template arrmuiltmodwithcarry(x,y,w){
    signal input a[x];
    signal input b[y];
    signal a2[x+1] <== carryarr(x,w)(a);
    signal b2[y+1] <== carryarr(y,w)(b);
    signal ab[x+y+1] <== arrmuiltnocarry(x+1,y+1)(a2,b2);
    signal mid[x+y+2] <== carryarr(x+y+1,w)(ab);
    signal output out[x+y+1];
    for (var i=0;i<x+y+1;i++)
        out[i] <== mid[i];
}

template arrmuiltthree(n,w){
    signal input a[n];
    signal input b[n];
    signal input c[n];
    signal a2[2*n+1] <== arrmuiltmodwithcarry(n,n,w)(a,b);
    signal a3[3*n+2] <== arrmuiltmodwithcarry(2*n+1,n,w)(a2,c);
    signal output out[3*n+1];
    for (var i=0;i<3*n+1;i++)
       out[i] <== a3[i]; 
}

//以2**w進位來比較兩組數
template modlessthan(n,w){
    signal input a[n];
    signal input b[n];
    signal a2[n+1] <== carryarr(n,w)(a);
    signal b2[n+1] <== carryarr(n,w)(b);
    var i;
    signal lessarr[n+1] ;
    signal equalarr[n+1] ;
    for (i=0;i<n+1;i++){
        lessarr[i] <== LessThan(w)([a2[i],b2[i]]);
        equalarr[i] <== IsEqual()([a2[i],b2[i]]);
    }
    component ands[n+1],eands[n+1],ors[n+1];
    for (i=n;i>=0;i--){
        ands[i]=AND();
        eands[i]=AND();
        ors[i]=OR();
        if (i==n){
            ands[i].a <== lessarr[i-1];
            ands[i].b <== equalarr[i];
            eands[i].a <== equalarr[i];
            eands[i].b <== equalarr[i-1];
            ors[i].a <== lessarr[i];
            ors[i].b <== ands[i].out;
        }else{
            ands[i].a <== lessarr[i];
            ands[i].b <== eands[i+1].out;
            eands[i].a <== equalarr[i];
            eands[i].b <== eands[i+1].out;
            ors[i].a <== ors[i+1].out;
            ors[i].b <== ands[i].out;
        }
    }
    signal output out <== ors[0].out;
}
