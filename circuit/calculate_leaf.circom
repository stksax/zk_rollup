pragma circom 2.1.5;
include "../node_modules/circomlib/circuits/babyjub.circom";
include "../node_modules/circomlib/circuits/escalarmulany.circom";
include "../node_modules/circomlib/circuits/bitify.circom";

template creat(){
    signal input pkx;
    signal input pky;

    signal input balance;
    signal balance_bin[253] <== Num2Bits(253)(balance);
    component EscalarMulAny = EscalarMulAny(253);
    EscalarMulAny.p[0] <== 21119053946455892568516594291439644903063966446263524955201963970341753018642;
    EscalarMulAny.p[1] <== 9527219423449754940117349193857779750179147628699894025560739076556827415027;
    for (var i=0;i<253;i++)
        EscalarMulAny.e[i] <== balance_bin[i];
    signal BHx <== EscalarMulAny.out[0];    
    signal BHy <== EscalarMulAny.out[1]; 
    
    component BabyAdd=BabyAdd();
    BabyAdd.x1 <== BHx;
    BabyAdd.y1 <== BHy;
    BabyAdd.x2 <== pkx;
    BabyAdd.y2 <== pky;
    signal output leafx <== BabyAdd.xout;
    signal output leafy <== BabyAdd.yout;
}

template minus(){
    signal input pkx;
    signal input pky;
    signal input leafx;
    signal input leafy;
    signal input payment;
    signal payment_bin[253] <== Num2Bits(253)(payment);
    component EscalarMulAny = EscalarMulAny(253);
    EscalarMulAny.p[0] <== 21119053946455892568516594291439644903063966446263524955201963970341753018642;
    EscalarMulAny.p[1] <== 9527219423449754940117349193857779750179147628699894025560739076556827415027;
    for (var i=0;i<253;i++)
        EscalarMulAny.e[i] <== payment_bin[i];
    signal paymentx <== EscalarMulAny.out[0];    
    signal paymenty <== EscalarMulAny.out[1]; 
    

    component BabyAdd=BabyAdd();
    BabyAdd.x1 <== leafx;
    BabyAdd.y1 <== leafy;
    BabyAdd.x2 <== -pkx;
    BabyAdd.y2 <== pky;
    signal x1 <== BabyAdd.xout;//balance*H
    signal y1 <== BabyAdd.yout;

    component BabyAdd2=BabyAdd();
    BabyAdd2.x1 <== x1;
    BabyAdd2.y1 <== y1;
    BabyAdd2.x2 <== -paymentx;
    BabyAdd2.y2 <== paymenty;
    signal x2 <== BabyAdd2.xout;
    signal y2 <== BabyAdd2.yout;

    component BabyAdd3=BabyAdd();
    BabyAdd3.x1 <== pkx;
    BabyAdd3.y1 <== pky;
    BabyAdd3.x2 <== x2;
    BabyAdd3.y2 <== y2;
    signal output new_leaf_x <== BabyAdd3.xout;
    signal output new_leaf_y <== BabyAdd3.yout;
}

template add(){
    signal input pkx;
    signal input pky;
    signal input leafx;
    signal input leafy;
    signal input payment;
    signal payment_bin[253] <== Num2Bits(253)(payment);
    component EscalarMulAny = EscalarMulAny(253);
    EscalarMulAny.p[0] <== 21119053946455892568516594291439644903063966446263524955201963970341753018642;
    EscalarMulAny.p[1] <== 9527219423449754940117349193857779750179147628699894025560739076556827415027;
    for (var i=0;i<253;i++)
        EscalarMulAny.e[i] <== payment_bin[i];
    signal paymentx <== EscalarMulAny.out[0];    
    signal paymenty <== EscalarMulAny.out[1]; 
    
    component BabyAdd=BabyAdd();
    BabyAdd.x1 <== leafx;
    BabyAdd.y1 <== leafy;
    BabyAdd.x2 <== -pkx;
    BabyAdd.y2 <== pky;
    signal x1 <== BabyAdd.xout;//balance*H
    signal y1 <== BabyAdd.yout;

    component BabyAdd2=BabyAdd();
    BabyAdd2.x1 <== x1;
    BabyAdd2.y1 <== y1;
    BabyAdd2.x2 <== paymentx;
    BabyAdd2.y2 <== paymenty;
    signal x2 <== BabyAdd2.xout;
    signal y2 <== BabyAdd2.yout;

    component BabyAdd3=BabyAdd();
    BabyAdd3.x1 <== pkx;
    BabyAdd3.y1 <== pky;
    BabyAdd3.x2 <== x2;
    BabyAdd3.y2 <== y2;
    signal output new_leaf_x <== BabyAdd3.xout;
    signal output new_leaf_y <== BabyAdd3.yout;
}