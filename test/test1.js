const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;

const assert = chai.assert;

describe("transaction test, if the transaction success, the receipt list will add the payment of it", function () {
    let circuit;
    let eddsa;
    let babyJub;
    let F;

    this.timeout(100000);

    before( async () => {
        eddsa = await buildEddsa();
        babyJub = await buildBabyjub();
        F = babyJub.F;
        circuit = await wasm_tester(path.join(__dirname, "../circuit/circuit.circom"));
        creat_message= await wasm_tester(path.join(__dirname, "circuits", "make_message.circom"));
        creat_test= await wasm_tester(path.join(__dirname, "circuits", "generate_leaf.circom"));
    });

    //this can be offer by bank
    const Alice_leaf_x="14300473964652011667050036391184662120521850930008164866589723675210657273755";
    const Alice_leaf_y="15497696423712032308821927760076543460883898784900168212404324272807389173452";
    const Bob_leaf_x="6673469457275726045665263634272671784275163661542286658106586149008685066633";
    const Bob_leaf_y="11953960145478372707268796818907269555481351742592604938852578426728246321167 ";
    const Chris_leaf_x="16047654317094242250349359542360571061933812287891527111556455914326245331770 ";
    const Chris_leaf_y="3324570614152475636635898490725373041207912059808505285271757178963057648573 ";
    const Alice_account_path=["18933334234117846673710878366312967447563874849912882306082985997953914408621",
        "15304123031794042892089670997043915742377006021656574090336323413885690017679","6488673646603647518705268581653658946519613576881584684249384467682521545402"];
    const Bob_account_path=["6844113909430542275611179983591105767070224029420610030856480815580942745395",
        "13761629597891660867219406965685130224221984273307079266383372207634242393068","6488673646603647518705268581653658946519613576881584684249384467682521545402"];
    const Chris_account_path=["13363749953045294108525919356271695915647673160159901210996868748815387250468",
        "597954442698209419274850708003643658045635445641904311813607827595157416207","3945603201662712780116976217010028808097124193349821260965764013213095921796"];

    it("Alice have 200, she transfer 150 to Bob , 50 to Chris", async () => {

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_leaf_x][reciever_leaf_y]
        //do what : 0 = withdraw, 1 = pay , 2 = save money
        let message1;
        message1 = await creat_message.calculateWitness({ in : [1,1,200,150,3,Bob_leaf_x,Bob_leaf_y] }, true);
        const msg1 = F.e(message1[1]);
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,1,200,50,5,Chris_leaf_x,Chris_leaf_y] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Alice_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Alice_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Alice_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Alice_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,150,3,Bob_leaf_x,Bob_leaf_y] , [1,1,200,50,5,Chris_leaf_x,Chris_leaf_y]],
            root: "21333424320790798199537135111871549301647283106813857717242381729307787374324",
            path_element: [Alice_account_path,Alice_account_path],
            reciever_path_element: [Bob_account_path,Chris_account_path]
        };

        const w = await circuit.calculateWitness(input, true);

        //the result is Alice (account location 1) transfer 200 for total, Bob (location 3) get 150, Chris get 50 (at location 5)
        //reduce_payment_list=[account location][new balance = 200-150-50 =0]
        //add_payment_list= [account location][payment]
        await circuit.assertOut(w, {reduce_payment_list : [[1,0],[1,0]], add_payment_list : [[3,150],[5,50]]});  
    });

    it("Alice withdraw 150, and Chris pay 75 to Alice", async () => {

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_leaf_x][reciever_leaf_y]
        //do what : 0 = withdraw, 1 = pay , 2 = save money
        let message1;
        message1 = await creat_message.calculateWitness({ in : [0,1,200,150,1,Alice_leaf_x,Alice_leaf_y] }, true);
        const msg1 = F.e(message1[1]);
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,5,100,75,1,Alice_leaf_x,Alice_leaf_y] }, true);
        const msg2 = F.e(message2[1]);
        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const signature2 = eddsa.signPoseidon(Chris_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Chris_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Chris_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Chris_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[0,1,200,150,1,Alice_leaf_x,Alice_leaf_y] , [1,5,100,75,1,Alice_leaf_x,Alice_leaf_y]],
            root: "21333424320790798199537135111871549301647283106813857717242381729307787374324",
            path_element: [Alice_account_path, Chris_account_path],
            reciever_path_element:[Alice_account_path, Alice_account_path]
        };

        const w = await circuit.calculateWitness(input, true);

        //Alice balance change to 125 (200-150+75=125) , Chris = 100 -75 = 25
        //and in add_payment_list Alice didn't gain payment, because it had been add to her balance in last step 
        await circuit.assertOut(w, {reduce_payment_list : [[1,125],[5,25]], add_payment_list : [[1,0],[1,0]]}); 
    });

    it("Alice want to transfer 250 to Bob, but her balance isn't enough, and Chris save 300", async () => {

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_leaf_x][reciever_leaf_y]
        //do what : 0 = withdraw, 1 = pay , 2 = save money
        let message1;
        message1 = await creat_message.calculateWitness({ in : [1,1,200,250,3,Bob_leaf_x,Bob_leaf_y] }, true);
        const msg1 = F.e(message1[1]);
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [2,5,100,300,5,Chris_leaf_x,Chris_leaf_y] }, true);
        const msg2 = F.e(message2[1]);
        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const signature2 = eddsa.signPoseidon(Chris_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Chris_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Chris_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Chris_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,250,3,Bob_leaf_x,Bob_leaf_y] , [2,5,100,300,5,Chris_leaf_x,Chris_leaf_y]],
            root: "21333424320790798199537135111871549301647283106813857717242381729307787374324",
            path_element: [Alice_account_path, Chris_account_path],
            reciever_path_element:[Bob_account_path, Chris_account_path]
        };

        const w = await circuit.calculateWitness(input, true);

        //because the first transaction didn't success, Alice balance didn't been change, Bob didn't get payment too
        //and you can see Chris balance become 400 after she store 300 into her account
        await circuit.assertOut(w, {reduce_payment_list : [[1,200],[5,400]], add_payment_list : [[3,0],[5,0]]}); 
    });

});
