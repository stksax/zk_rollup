pragma circom 2.1.5;
include "circomlib/bitify.circom";
include "circomlib/gates.circom";
include "muilt.circom";
include "sub.circom";
//it used for verify the point(x,y) is in sepc256k1 cruve, key*g=(x,y) , g means the base point (g=x252[0],y252[0])
//if key is given, it can be verify in 252 round of count (key is in range of 1~2**252)
//first we check x252 and y252 is correct 
//and change the key to binary, so it can be 2**a * 2**b *2**c == 2**(a+b+c) , a+b+c=key
//path means every step we verify, if key = [1,0,1,1], path=[1,1,5,13], path[n-1] == x,y
//because circom have limit on counting (limit around 2**252), so i had writted bigint counting(bigadd, muilt, sud)
//number had been mod with 2**126, so it will not be more than 2**252 if we muilt
//and after we verify the point we can verify if it is in merkle tree,and merkle tree's hasher i used keccak256
template ecdsa(n){
    signal input x[n];
    signal input y[n];
    signal input key;
    signal n2b[252] <== Num2Bits(252)(key);
    signal not_in_path[252];
    component XOR[252];
    for (var i=0;i<252;i++){
        XOR[i]=XOR();
        XOR[i].a <== n2b[i];
        XOR[i].b <== 1;
        not_in_path[i] <== XOR[i].out;
    }
    //point on 2**n and on cruve
    signal input x252[252][n];
    signal input y252[252][n];
    signal input y252_positive[252];
    component check=check(n);
    check.x <== x252;
    check.y <== y252;
    check.y_is_positive <== y252_positive;
    signal input pathx[252][n];
    signal input pathy[252][n];
    signal input pathy_positive[252];
    component point_add[251];
    signal forcount1[256][n];
    signal forcount2[256][n];
    signal forcount3[256];
    signal forcount4[256][n];
    signal forcount5[256][n];
    var i,j;
    for (i=1;i<251;i++){
        point_add[i]=point_add(n);
        point_add[i].ay_is_positive <== y252_positive[i];
        forcount3[i] <== not_in_path[i] * y252_positive[i];
        point_add[i].by_is_positive <== n2b[i] * pathy_positive[i-1] + forcount3[i];
        for (j=0;j<n;j++){
            point_add[i].ax[j] <== x252[i][j];
            point_add[i].ay[j] <== y252[i][j];
            forcount1[i][j] <== not_in_path[i] * x252[i-1][j];
            forcount2[i][j] <== not_in_path[i] * y252[i-1][j];
            point_add[i].bx[j] <== n2b[i] * pathx[i-1][j] + forcount1[i][j];
            point_add[i].by[j] <== n2b[i] * pathy[i-1][j] + forcount2[i][j];
            forcount4[i][j] <== not_in_path[i] * x252[i][j];
            forcount5[i][j] <== not_in_path[i] * y252[i][j];
            point_add[i].cx[j] <== n2b[i] * pathx[i][j] + forcount4[i][j];
            point_add[i].cy[j] <== n2b[i] * pathy[i][j] + forcount5[i][j];
        }
    }

    for (var i=0;i<n;i++){
        pathx[251][i] === x[i];
        pathy[251][i] === y[i];
    }
}

//y**2=x**3+7
template oncurve(n){
    signal input x[n];
    signal input y[n];
    signal x3[3*n+1] <== arrmuiltthree(n,126)(x,x,x);
    signal y2[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(y,y);
    component arrsub=arrsub(3*n+1,126);
    arrsub.a[0] <== y2[0];
    arrsub.b[0] <== x3[0]+7;
    for (var i=1;i<3*n+1;i++){
        if (i<2*n+1){
            arrsub.a[i] <== y2[i];
            arrsub.b[i] <== x3[i];
        }else{
            arrsub.a[i] <== 0;
            arrsub.b[i] <== x3[i];
        }
    }
    for (var i=0;i<3*n+1;i++)
        arrsub.out[i] === 0;
}

//x1^3 + x2^3 - x1^2x2 - x1x2^2 + x2^2x3 + x1^2x3 - 2x1x2x3 - y2^2 + 2y1y2 - y1^2 = 0 
template point_add(n){
    signal input ax[n];
    signal input ay[n];
    signal input ay_is_positive;
    signal input bx[n];
    signal input by[n];
    signal input by_is_positive;
    signal input cx[n];
    signal input cy[n];
    signal ax3[3*n+1] <== arrmuiltthree(n,126)(ax,ax,ax);
    signal bx3[3*n+1] <== arrmuiltthree(n,126)(bx,bx,bx);
    signal ax2bx[3*n+1] <== arrmuiltthree(n,126)(ax,ax,bx);
    signal axbx2[3*n+1] <== arrmuiltthree(n,126)(bx,bx,ax);
    signal bx2cx[3*n+1] <== arrmuiltthree(n,126)(bx,bx,cx);
    signal ax2cx[3*n+1] <== arrmuiltthree(n,126)(ax,ax,cx);
    signal axbxcx[3*n+1] <== arrmuiltthree(n,126)(ax,bx,cx);
    signal ay2[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(ay,ay);
    signal by2[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(by,by);
    signal ayby[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(ay,by);
    signal z1 <== XOR()(ay_is_positive,by_is_positive);
    signal z2 <== XOR()(z1,1);
    component arrsub=arrsub(3*n+1,126);
    for (var i=0;i<3*n+1;i++){
        if (i<2*n+1){
            arrsub.a[i] <== ax3[i] + bx3[i] + ax2cx[i] + bx2cx[i] + 2*z2*ayby[i];
            arrsub.b[i] <== ax2bx[i] + axbx2[i] + 2*axbxcx[i] + ay2[i] +  2*z1*ayby[i] + ayby[i];
        }else{
            arrsub.a[i] <== ax3[i] + bx3[i] + ax2cx[i] + bx2cx[i];
            arrsub.b[i] <== ax2bx[i] + axbx2[i] + 2*axbxcx[i];
        }
    }
    for (var i=0;i<3*n+1;i++)
        arrsub.out[i] === 0;
}
//y2_is_positive most be change，i assert point1 is (x1,y1), point2 is(x2,-y2)
//slope=3*x1**2/2*y1
//x2=slope**2-2*x1
//y2=slope*(x1-x2)-y1
template double_point_add(n){
    signal input x1[n];
    signal input y1[n];
    signal input y1_is_positive;
    signal input x2[n];
    signal input y2[n];
    signal input y2_is_positive;
    signal x13[3*n+1] <== arrmuiltthree(n,126)(x1,x1,x1);
    signal x14[4*n+2] <== arrmuiltmodwithcarry(3*n+1,n,126)(x13,x1);
    signal x1y12[3*n+1] <== arrmuiltthree(n,126)(x1,y1,y1);
    signal x2y12[3*n+1] <== arrmuiltthree(n,126)(x2,y1,y1);
    component arrsub=arrsub(4*n+2,126);
    for (var i=0;i<4*n+2;i++){
        if (i<3*n+1){
            arrsub.a[i] <== 9*x14[i];
            arrsub.b[i] <== 8*x1y12[i] + 4*x2y12[i];
        }else{
            arrsub.a[i] <== 9*x14[i];
            arrsub.b[i] <== 0;
        }
    }
    for (var i=0;i<4*n+2;i++)
        arrsub.out[i] === 0;

    signal x12x2[3*n+1] <== arrmuiltthree(n,126)(x1,x1,x2);
    signal y12[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(y1,y1);
    signal y1y2[2*n+1] <== arrmuiltmodwithcarry(n,n,126)(y1,y2);
    signal z1 <== XOR()(y1_is_positive,y2_is_positive);
    signal z2 <== XOR()(z1,1);
    component arrsub2=arrsub(3*n+1,126);
    for (var i=0;i<3*n+1;i++){
        if (i<2*n+1){
            arrsub2.a[i] <== 3*x13[i]+z1*y1y2[i];
            arrsub2.b[i] <== 3*x12x2[i] +2*y12[i]+z2*y1y2[i];
        }else{
            arrsub2.a[i] <== 3*x13[i];
            arrsub2.b[i] <== 3*x12x2[i];
        }
    }
}
//make sure x[252][n]and y[252][n] represent 2**i (i=0~252) and it is on sepc256k
template check(n){
    signal input x[252][n];
    signal input y[252][n];
    signal input y_is_positive[252];
    component double_point_add[252];
    signal inverse_y[252];
    component XOR[252];
    for (var i=0;i<252;i++){
        XOR[i]=XOR();
        XOR[i].a <== y_is_positive[i];
        XOR[i].b <== 1;
        inverse_y[i] <== XOR[i].out;
    }
    for (var i=0;i<251;i++){
        double_point_add[i]=double_point_add(n);
        double_point_add[i].y1_is_positive <== inverse_y[i];
        double_point_add[i].y2_is_positive <== inverse_y[i+1];
        for (var j=0;j<n;j++){
            double_point_add[i].x1[j] <== x[i][j];
            double_point_add[i].y1[j] <== y[i][j];
            double_point_add[i].x2[j] <== x[i+1][j];
            double_point_add[i].y2[j] <== y[i+1][j];
        }
    }
    component oncurve[252];
    for (var i=0;i<252;i++){
        oncurve[i]=oncurve(n);
        for (var j=0;j<n;j++){
            oncurve[i].x[j] <== x[i][j];
            oncurve[i].y[j] <== y[i][j];
        }
    }
}
