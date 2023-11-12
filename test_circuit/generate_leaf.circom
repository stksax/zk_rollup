pragma circom 2.1.5;

include "../../../node_modules/circomlib/circuits/babyjub.circom";
include "../../../node_modules/circomlib/circuits/poseidon.circom";
include "../../../node_modules/circomlib/circuits/escalarmulany.circom";
include "../../../node_modules/circomlib/circuits/bitify.circom";

//this template should not exist on the real project
//it just for verify the account information is correct after the transaction
template generate_leaf(n){
    signal input pkx[n];
    signal input pky[n];
    
    signal input balance[n];
    signal balance_bin[n][252];
    component Num2Bits[n];
    for (var i=0;i<n;i++){
        Num2Bits[i]=Num2Bits(252);
        Num2Bits[i].in <== balance[i];
        for (var j=0;j<252;j++){
            balance_bin[i][j] <== Num2Bits[i].out[j];
        }
    }

    signal BHx[n];
    signal BHy[n];
    component EscalarMulAny[n];
    for (var i=0;i<n;i++){
        EscalarMulAny[i] = EscalarMulAny(252);
        EscalarMulAny[i].p[0] <== 21119053946455892568516594291439644903063966446263524955201963970341753018642;
        EscalarMulAny[i].p[1] <== 9527219423449754940117349193857779750179147628699894025560739076556827415027;
        for (var j=0;j<252;j++){
            EscalarMulAny[i].e[j] <== balance_bin[i][j];
        }
        BHx[i] <== EscalarMulAny[i].out[0];    
        BHy[i] <== EscalarMulAny[i].out[1]; 
    }

    signal output x[n];
    signal output y[n];
    component BabyAdd[n];
    for (var i=0;i<n;i++){
        BabyAdd[i]=BabyAdd();
        BabyAdd[i].x1 <== BHx[i];
        BabyAdd[i].y1 <== BHy[i];
        BabyAdd[i].x2 <== pkx[i];
        BabyAdd[i].y2 <== pky[i];
        x[i] <== BabyAdd[i].xout;
        y[i] <== BabyAdd[i].yout;
    }
    
    signal point[n];
    for (var i=0;i<n;i++)
       point[i] <== Poseidon(2)([x[i],y[i]]);
}

component main=generate_leaf(3);