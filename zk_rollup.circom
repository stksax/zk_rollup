pragma circom 2.1.5;

include "../../node_modules/circomlib/circuits/babyjub.circom";
include "../../node_modules/circomlib/circuits/poseidon.circom";
include "../../node_modules/circomlib/circuits/escalarmulany.circom";
include "../../node_modules/circomlib/circuits/eddsaposeidon.circom";
include "../../node_modules/circomlib/circuits/bitify.circom";
include "../../node_modules/circomlib/circuits/gates.circom";
include "../../node_modules/circomlib/circuits/comparators.circom";
include "merkle_tree.circom";
include "calculate_leaf.circom";
//this template can verify the transaction and generate two list , who get payment for how much, and who spend who much
//and after get this two lists, the template update leaf can generate new leaf of merkle tree
template transaction(n,layer){
    signal input Ax[n];//sender_pubkey_x
    signal input Ay[n];//sender_pubkey_y

    signal input S[n];
    signal input R8x[n];
    signal input R8y[n];

    signal input m[n][7];//[do what][sender account location][sender_balance][payment][reciever_location][reciever_leaf_x][reciever_leaf_y]
    //[do what] 0= withdraw 1=pay  2=save
    //in saving and withdraw, reciever_pubkey_x = sender_pubkey_x
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

    signal sender_leaf_x[n];
    signal sender_leaf_y[n];
    component creat[n];
    for (var i=0;i<n;i++){
        creat[i]=creat();
        creat[i].pkx <== Ax[i];
        creat[i].pky <== Ay[i];
        creat[i].balance <== m[i][2];
        sender_leaf_x[i] <== creat[i].leafx;
        sender_leaf_y[i] <== creat[i].leafy;
    }

    //check in merkle tree
    signal input root;
    signal input path_element[n][layer];
    component sender_in_merkle_tree[n];
    signal in_tree_check1[n];
    for (var i=0;i<n;i++){
        sender_in_merkle_tree[i]=in_merkle_tree(layer);
        sender_in_merkle_tree[i].leaf <== Poseidon(2)([sender_leaf_x[i],sender_leaf_y[i]]);//pubkey and balance
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
        reciever_in_merkle_tree[i].leaf <== Poseidon(2)([m[i][5], m[i][6]]);//reciever_leaf_x,reciever_leaf_y
        reciever_in_merkle_tree[i].route <== m[i][4];//account location
        reciever_in_merkle_tree[i].root <== root;
        for (var j=0;j<layer;j++){
            reciever_in_merkle_tree[i].path_element[j] <== reciever_path_element[i][j];
        }
        in_tree_check2[i] <== reciever_in_merkle_tree[i].out;
    }
    
    //if both sender and reciever's information is correct, the transaction will be accept
    signal is_valid[n];
    for (var i=0;i<n;i++)
        is_valid[i] <== AND()(in_tree_check1[i], in_tree_check2[i]);

    signal output reduce_payment_list[n][2];//[who][his balance should reduce]
    component reduce_balance=reduce_balance(n);
    signal pre_payment[n];
    signal balance_enough[n];
    for (var i=0;i<n;i++){
        reduce_balance.sender_list[i][0] <== m[i][1];//sender location
        reduce_balance.sender_list[i][1] <== m[i][2];// sender balance
        reduce_balance.sender_list[i][2] <== m[i][3] * is_valid[i]; //payment
        reduce_balance.reciever_list[i][0] <== m[i][4]; //reciever location
        pre_payment[i] <== m[i][3] * is_valid[i]; 
        reduce_balance.reciever_list[i][1] <== m[i][0] * pre_payment[i]; 
    }
    for (var i=0;i<n;i++){
        reduce_payment_list[i][0] <== reduce_balance.out[i][0];
        reduce_payment_list[i][1] <== reduce_balance.out[i][1] * is_valid[i];
        balance_enough[i] <== reduce_balance.balance_enough[i];
    }

    //if you transfer to someome and the other also transfer to you, the add paymeny list will show 0
    //because the payment you get had integrate with the money you pay
    signal output add_payment_list[n][2];//[who][he will get how much payment]
    component add_balance = add_balance(n);
    for (var i=0;i<n;i++){
        add_balance.sender_list[i][0] <== m[i][1];//sender location
        add_balance.sender_list[i][1] <== m[i][2];// sender balance
        add_balance.sender_list[i][2] <== m[i][3] * is_valid[i]; //payment
        add_balance.reciever_list[i][0] <== m[i][4]; //reciever location
        add_balance.reciever_list[i][1] <== m[i][0] * pre_payment[i];
        add_balance.balance_enough[i] <== balance_enough[i]; 
    }
    
    for (var i=0;i<n;i++){
        add_payment_list[i][0] <== add_balance.out[i][0];
        //if it is withdraw(m[i][0]=0) the balance shouldn't add
        //if it is saving money (m[i][0]=2), it will be add twise, because in the next step it will be minus one time  
        //so in saving money you will get double payment, and minus one in next step
        add_payment_list[i][1] <== add_balance.out[i][1];
    }
}

template update_leaf1(n){
    signal input minus_list[n][4];//[account_location][pubkey_x][pubkey_y][new balance]

    signal output new_leaf[n][3];//[account_location][new leafx][new leafy]
    component creat[n];
    for (var i=0;i<n;i++){
        creat[i] = creat();
        creat[i].pkx <== minus_list[i][1];
        creat[i].pky <== minus_list[i][2];
        creat[i].balance <== minus_list[i][3];
        new_leaf[i][0] <== minus_list[i][0];
        new_leaf[i][1] <== creat[i].leafx;
        new_leaf[i][2] <== creat[i].leafy;
    }
}

template update_leaf2(n){
    signal input old_leaf[n][4];//[pubkey_x][pubkey_y][previous_leafx][previous_leafy]
    signal input add_list[n][2];//[account_location][payment]
    signal output new_leaf[n][3];//[account_location][new_leaf_x][new_leaf_y]
    component add[n];
     for (var i=0;i<n;i++){
        add[i] = add();
        add[i].pkx <== old_leaf[i][0];
        add[i].pky <== old_leaf[i][1];
        add[i].leafx <== old_leaf[i][2];
        add[i].leafy <== old_leaf[i][3];
        add[i].payment <== add_list[i][1];
        new_leaf[i][0] <== add_list[i][0];
        new_leaf[i][1] <== add[i].new_leaf_x;
        new_leaf[i][2] <== add[i].new_leaf_y;
    }
}

template rollup(all,new){
    signal input leaf_does_not_change[all-new][3];//[location][leafx][leafy]
    signal input update_leaf[new][3];//[location][leafx][leafy]
    signal new_leaf1[all][2];
    
    component IsEqual[all*all];
    signal record1[all*all];
    signal record2[all*all];
    for (var i=0;i<all;i++){
        var c1=0;
        var c2=0;
        for (var j=0;j<all;j++){
            IsEqual[i*all+j] = IsEqual();
            IsEqual[i*all+j].in[0] <== i;
            if (j<new){
                IsEqual[i*all+j].in[1] <== update_leaf[j][0];
                record1[i*all+j] <== IsEqual[i*all+j].out * update_leaf[j][1];
                record2[i*all+j] <== IsEqual[i*all+j].out * update_leaf[j][2];
                c1 += record1[i*all+j];
                c2 += record2[i*all+j];
            }else{
                IsEqual[i*all+j].in[1] <== leaf_does_not_change[j-new][0];
                record1[i*all+j] <== IsEqual[i*all+j].out * leaf_does_not_change[j-new][1];
                record2[i*all+j] <== IsEqual[i*all+j].out * leaf_does_not_change[j-new][2];
                c1 += record1[i*all+j];
                c2 += record2[i*all+j];
            }
        }
        new_leaf1[i][0] <== c1;
        new_leaf1[i][1] <== c2;
    }

    var n=all/2;
    signal new_leaf[n];
    for (var i=0;i<n;i++)
        new_leaf[i] <== Poseidon(2)([new_leaf1[i][0], new_leaf1[i][1]]);

    //make new merkle root
    signal node[n-1];
    var counter=0;
    component Poseidon[n-1];
    for (var i=0;i<n-1;i++){
        Poseidon[i]=Poseidon(2);
        if (i<n/2){
            Poseidon[i].inputs[0] <== new_leaf[2*i];
            Poseidon[i].inputs[1] <== new_leaf[2*i+1];
            node[i] <== Poseidon[i].out;
            counter+=1;
        }else{
            Poseidon[i].inputs[0] <== node[(i-counter)*2];
            Poseidon[i].inputs[1] <== node[(i-counter)*2+1];
            node[i] <== Poseidon[i].out;
        }
    }
    signal output root <== node[n-2];
}


template add_balance(n){
    signal input sender_list[n][3];//[who][blance][pay] , because we need to check the sender didn't spend more than his balance
    signal input reciever_list[n][2];//[who][get pay how much]
    signal input balance_enough[n];
    signal payment[n*n];
    signal payment2[n*n];
    component IsEqual[n*n];
    component IsUnEqual[n*n];
    signal pre_out[n][2];
    signal output out[n][2];
    for (var i=0;i<n;i++){
        var total=0;
        out[i][0] <== reciever_list[i][0];
        for (var j=0;j<n;j++){
            IsEqual[i*n+j]=IsEqual();
            IsEqual[i*n+j].in[0] <== reciever_list[i][0];
            IsEqual[i*n+j].in[1] <== reciever_list[j][0];
            payment[i*n+j] <== IsEqual[i*n+j].out * reciever_list[j][1];
            total += payment[i*n+j];
        }
        pre_out[i][1] <== total * balance_enough[i];

        for (var j=0;j<n;j++){
            IsUnEqual[i*n+j]=IsUnEqual();
            IsUnEqual[i*n+j].in[0] <== reciever_list[i][0];
            IsUnEqual[i*n+j].in[1] <== sender_list[j][0];
            if (j == 0){
                payment2[i*n+j] <== IsUnEqual[i*n+j].out * pre_out[i][1];
            }if (j>0 && j<n-1){
                payment2[i*n+j] <== IsUnEqual[i*n+j].out * payment2[i*n+j-1];
            }if (j == n-1){
                out[i][1] <== IsUnEqual[i*n+j].out * payment2[i*n+j-1];
            }
        }
    }   
}

template reduce_balance(n){
    signal input sender_list[n][3];//[sender location][blance][payment] 
    signal input reciever_list[n][2];//[reciever location][payment]
    signal payment[2*n*n];
    component IsEqual[2*n*n];
    signal output out[n][2];
    signal output balance_enough[n];
    for (var i=0;i<n;i++){
        var total=0;
        out[i][0] <== sender_list[i][0];
        for (var j=0;j<2*n;j++){
            if (j<n){
                IsEqual[i*2*n+j]=IsEqual();
                IsEqual[i*2*n+j].in[0] <== sender_list[i][0];
                IsEqual[i*2*n+j].in[1] <== sender_list[j][0];
                payment[i*2*n+j] <== IsEqual[i*2*n+j].out * sender_list[j][2];
                total += payment[i*2*n+j];
            }else{
                IsEqual[i*2*n+j]=IsEqual();
                IsEqual[i*2*n+j].in[0] <== sender_list[i][0];
                IsEqual[i*2*n+j].in[1] <== reciever_list[j-n][0];
                payment[i*2*n+j] <== IsEqual[i*2*n+j].out * reciever_list[j-n][1];
                total -= payment[i*2*n+j];
            }
        }
        //make sure balance enough
        balance_enough[i] <== LessEqThan(252)([total, sender_list[i][1]]);
        out[i][1] <== sender_list[i][1] - total * balance_enough [i];
    }
}

template IsUnEqual() {
    signal input in[2];
    signal output out;

    component isz = IsZero();

    in[1] - in[0] ==> isz.in;

    signal out0 <== isz.out;
    out <== XOR()(out0,1);
}
