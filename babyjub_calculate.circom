pragma circom 2.1.5;
include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "keccak.circom";

template calculate_point(n){
    signal input private_key;
    signal key[n] <== Num2Bits(n)(private_key);
    signal r1x[n];
    signal r1y[n];
    signal r2x[n];
    signal r2y[n];
    component BabyDbl[n];
    r2x[0] <== 995203441582195749578291179787384436505546430278305826713579947235728471134;
    r2y[0] <== 5472060717959818805561601436314318772137091100104008585924551046643952123905;
    for (var i=1;i<n;i++){
        BabyDbl[i]=BabyDbl();
        BabyDbl[i].x <== r2x[i-1];
        BabyDbl[i].y <== r2y[i-1];
        r2x[i] <== BabyDbl[i].xout;
        r2y[i] <== BabyDbl[i].yout;
    }

    r1x[0] <== key[0] * r2x[0];
    r1y[0] <== key[0] * (r2y[0]-1)+1;
    
    component BabyAdd[n];
    for (var i=1;i<n;i++){
        BabyAdd[i]=BabyAdd();
        BabyAdd[i].x1 <== r1x[i-1];
        BabyAdd[i].y1 <== r1y[i-1];
        BabyAdd[i].x2 <== key[i] * r2x[i];
        BabyAdd[i].y2 <== key[i] * (r2y[i]-1) + 1;
        r1x[i] <== BabyAdd[i].xout;
        r1y[i] <== BabyAdd[i].yout;
    }
    signal output outx <== r1x[n-1];
    signal output outy <== r1y[n-1];
}

template point_times(n){
    signal input private_key;
    signal input original_x;
    signal input original_y;
    signal key[n] <== Num2Bits(n)(private_key);
    signal r1x[n];
    signal r1y[n];
    signal r2x[n];
    signal r2y[n];
    component BabyDbl[n];
    r2x[0] <== original_x;
    r2y[0] <== original_y;
    for (var i=1;i<n;i++){
        BabyDbl[i]=BabyDbl();
        BabyDbl[i].x <== r2x[i-1];
        BabyDbl[i].y <== r2y[i-1];
        r2x[i] <== BabyDbl[i].xout;
        r2y[i] <== BabyDbl[i].yout;
    }

    r1x[0] <== key[0] * r2x[0];
    r1y[0] <== key[0] * (r2y[0]-1)+1;
    
    component BabyAdd[n];
    for (var i=1;i<n;i++){
        BabyAdd[i]=BabyAdd();
        BabyAdd[i].x1 <== r1x[i-1];
        BabyAdd[i].y1 <== r1y[i-1];
        BabyAdd[i].x2 <== key[i] * r2x[i];
        BabyAdd[i].y2 <== key[i] * (r2y[i]-1) + 1;
        r1x[i] <== BabyAdd[i].xout;
        r1y[i] <== BabyAdd[i].yout;
    }
    signal output outx <== r1x[n-1];
    signal output outy <== r1y[n-1];
}

template sign(n){
    signal input private_key;
    signal input random_num;
    signal input reciver_public_key_x;
    signal input reciver_public_key_y;
    signal input payment;
    signal (diffie_hellman_key_x, diffie_hellman_key_y) <== point_times(n)(private_key, reciver_public_key_x, reciver_public_key_y);
    signal output (commitment_x, commitment_y) <== calculate_point(n)(random_num);
    signal output (public_key_x, public_key_y) <== calculate_point(n)(private_key);
    signal challenge[1] <== Keccak(5,1)([diffie_hellman_key_x, diffie_hellman_key_y, commitment_x, commitment_y, payment]);
    signal output response <== random_num + challenge[0] * private_key;
}
