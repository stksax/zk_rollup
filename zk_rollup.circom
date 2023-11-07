pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/escalarmulany.circom";
include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/gates.circom";
include "merkle_tree.circom";
//this template can verify the transaction and generate two list , who get payment for how much, and who spend who much
//and after get this two lists, the template update leaf can generate new leaf of merkle tree
template transaction(n,layer){
    signal input Ax[n];
    signal input Ay[n];

    signal input S[n];
    signal input R8x[n];
    signal input R8y[n];

    signal input m[n][7];//[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
    //[do what] 0= withdraw 1=pay  2=save
    //in saving and withdraw, reciever_pubkey_x = sender_pubkey_x(Ax)
    signal M[n];

    var i;
    for (i=0;i<n;i++)
        M[i] <== Poseidon(7)([m[i][0], m[i][1], m[i][2], m[i][3], m[i][4], m[i][5], m[i][6]]);

    //verify signature
    component EdDSAPoseidonVerifier[n];
    for (i=0;i<n;i++){
        EdDSAPoseidonVerifier[i] = EdDSAPoseidonVerifier();
        EdDSAPoseidonVerifier[i].enabled <== 1;
        EdDSAPoseidonVerifier[i].Ax <== Ax[i];
        EdDSAPoseidonVerifier[i].Ay <== Ay[i];
        EdDSAPoseidonVerifier[i].S <== S[i];
        EdDSAPoseidonVerifier[i].R8x <== R8x[i];
        EdDSAPoseidonVerifier[i].R8y <== R8y[i];
        EdDSAPoseidonVerifier[i].M <== M[i];
    }

    //check in merkle tree
    signal input root;
    signal input path_element[n][layer];
    component sender_in_merkle_tree[n];
    signal in_tree_check1[n];
    for (var i=0;i<n;i++){
        sender_in_merkle_tree[i]=in_merkle_tree(layer);
        sender_in_merkle_tree[i].leaf <== Poseidon(2)([Ax[i],m[i][2]]);//pubkey and balance
        sender_in_merkle_tree[i].route <== m[i][1];//account location
        sender_in_merkle_tree[i].root <== root;
        for (var j=0;j<layer;j++){
            sender_in_merkle_tree[i].path_element[j] <== path_element[i][j];
        }
        in_tree_check1[i] <== sender_in_merkle_tree[i].out;
    }

    signal input reciever_path_element[n][layer];
    component reciever_in_merkle_tree[n];
    signal in_tree_check2[n];
    for (var i=0;i<n;i++){
        reciever_in_merkle_tree[i]=in_merkle_tree(layer);
        reciever_in_merkle_tree[i].leaf <== Poseidon(2)([m[i][5], m[i][6]]);//pubkey and balance
        reciever_in_merkle_tree[i].route <== m[i][4];//account location
        reciever_in_merkle_tree[i].root <== root;
        for (var j=0;j<layer;j++){
            reciever_in_merkle_tree[i].path_element[j] <== reciever_path_element[i][j];
        }
        in_tree_check2[i] <== reciever_in_merkle_tree[i].out;
    }
    
    //if both sender and reciever's information is correct, the transaction will be accept
    signal is_valid[n];
    for (var i=0;i<n;i++){
        is_valid[i] <== AND()(in_tree_check1[i], in_tree_check2[i]);
    }

    signal output reduce_payment[n][2];//[who][his balance should reduce]
    component reduce_balance=reduce_balance(n);
    signal balance_enough[n];
    for (var i=0;i<n;i++){
        reduce_balance.in[i][0] <== Ax[i];
        reduce_balance.in[i][1] <== m[i][2];// sender balance
        reduce_balance.in[i][2] <== m[i][3] * is_valid[i]; //payment
    }
    for (var i=0;i<n;i++){
        reduce_payment[i][0] <== reduce_balance.out[i][0];
        reduce_payment[i][1] <== reduce_balance.out[i][1];
        balance_enough[i] <== reduce_balance.balance_enough[i];
    }

    signal output add_payment[n][2];//[who][his balance should add]
    component add_balance = add_balance(n);
    for (var i=0;i<n;i++){
        add_balance.in[i][0] <== m[i][5];
        add_balance.in[i][1] <== m[i][3] * is_valid[i];
        add_balance.balance_enough[i] <== balance_enough[i];
    }
    for (var i=0;i<n;i++){
        add_payment[i][0] <== add_balance.out[i][0];
        //if it is withdraw(m[i][0]=0) the balance shouldn't add
        //if it is saving money (m[i][0]=2), it will be add twise, because in the next step it will be minus one time  
        //so in saving money you will get double payment, and minus one in next step
        add_payment[i][1] <== add_balance.out[i][1] * m[i][0];
    }
}

template update_leaf(n){
    signal input add_list[n][4];//[who][account_location][original balance][add]
    signal input minus_list[n][4];//[who][account_location][original balance][minus]
    component IsEqual[2*n*n];
    for (var i=0;i<2*n;i++){
        for (var j=0;j<n;j++){
            IsEqual[i*n+j]=IsEqual();
            if (i < n){
                IsEqual[i*n+j].in[0] <== add_list[i][0];
                IsEqual[i*n+j].in[1] <== minus_list[j][0];
            }else{
                IsEqual[i*n+j].in[0] <== minus_list[i-n][0];
                IsEqual[i*n+j].in[1] <== add_list[j][0];
            }
        }
    }
    signal new_balance[2*n];
    signal output new_leaf[2*n][2];//[location][leaf]
    signal p[2*n*n];
    for (var i=0;i<2*n;i++){
        var count =0; 
        if (i < n){
            for (var j=0;j<n;j++){
                p[i*n+j] <== IsEqual[i*n+j].out * minus_list[j][3];
                count += p[i*n+j];
            }
            new_balance[i] <== add_list[i][2] + add_list[i][3] -count;
            new_leaf[i][0] <== add_list[i][1];
            new_leaf[i][1] <== Poseidon(2)([add_list[i][0],new_balance[i]]);
        }else{
            for (var j=0;j<n;j++){
                p[i*n+j] <== IsEqual[i*n+j].out * add_list[j][3];
                count += p[i*n+j];
            }
            new_balance[i] <== minus_list[i-n][2] - minus_list[i-n][3] + count;
            new_leaf[i][0] <== minus_list[i-n][1];
            new_leaf[i][1] <== Poseidon(2)([minus_list[i-n][0],new_balance[i]]);
        }
    }
}

template add_balance(n){
    signal input in[n][2];//[who][payment]
    signal input balance_enough[n];
    signal payment[n*n];
    component IsEqual[n*n];
    signal output out[n][2];
    for (var i=0;i<n;i++){
        var total=0;
        out[i][0] <== in[i][0];
        for (var j=0;j<n;j++){
            IsEqual[i*n+j]=IsEqual();
            IsEqual[i*n+j].in[0] <== in[i][0];
            IsEqual[i*n+j].in[1] <== in[j][0];
            payment[i*n+j] <== IsEqual[i*n+j].out * in[j][1];
            total += payment[i*n+j];
        }
        out[i][1] <== total * balance_enough[i];
    }   
}

template reduce_balance(n){
    signal input in[n][3];//[who][blance][pay] , because we need to check the sender didn't spend more than his balance
    signal payment[n*n];
    component IsEqual[n*n];
    signal output out[n][2];
    signal output balance_enough[n];
    for (var i=0;i<n;i++){
        var total=0;
        out[i][0] <== in[i][0];
        for (var j=0;j<n;j++){
            IsEqual[i*n+j]=IsEqual();
            IsEqual[i*n+j].in[0] <== in[i][0];
            IsEqual[i*n+j].in[1] <== in[j][0];
            payment[i*n+j] <== IsEqual[i*n+j].out * in[j][2];
            total += payment[i*n+j];
        }
        //make sure balance enough
        balance_enough[i] <== LessEqThan(252)([total, in[i][1]]);
        out[i][1] <== total * balance_enough [i];
    }
}
