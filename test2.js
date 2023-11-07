const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;

const assert = chai.assert;

describe("update merkle tree test", function () {
    let circuit;
    let eddsa;
    let babyJub;
    let F;

    this.timeout(100000);

    before( async () => {
        eddsa = await buildEddsa();
        babyJub = await buildBabyjub();
        F = babyJub.F;
        circuit = await wasm_tester(path.join(__dirname, "transaction.circom"));
        creat_message = await wasm_tester(path.join(__dirname, "make_message.circom"));
        update_merkle_leaf = await wasm_tester(path.join(__dirname, "update_leaf.circom"));
        make_merkle_leaf = await wasm_tester(path.join(__dirname, "make_merkle_leaf.circom"));
    });

    it("Alice pay 150 to Bob , Bob pay 50 to Chris, after they do the transaction, make the new merkle leaf", async () => {
        //Alice's blance = 200 - 150 = 50
        //Bob's blance = 50 + 150 - 50 = 150
        //Chris's blance = 100 + 50 = 150

        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const Alice_pubKey_x = F.toObject(Alice_pubKey[0]);

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
        const Bob_pubKey_x = F.toObject(Bob_pubKey[0]);

        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const Chris_pubKey_x = F.toObject(Chris_pubKey[0]);

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
        let message1;
        message1 = await creat_message.calculateWitness({ in : [1,1,200,150,3,Bob_pubKey_x,50] }, true);
        const msg1 = F.e(message1[1]);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,3,50,50,5,Chris_pubKey_x,100] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Bob_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Bob_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Bob_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Bob_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,150,3,Bob_pubKey_x,50], [1,3,50,50,5,Chris_pubKey_x,100]],
            root: "3652006791074245341020691209164424051782923244431348363960678455191886138263",
            path_element: [["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
            ["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"]],
            reciever_path_element:[["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
            ["2195283773519661462237754398261011259690524503682308555976902945904944128550","10763015501225546336671529484009936927811817407799068279554347677670247018881","14770585617228618795027130141265691945484501340838439114116037752024033203021"]]
        };

        const w = await circuit.calculateWitness(input, true);

        await circuit.assertOut(w, {add_payment : [[Bob_pubKey_x,150],[Chris_pubKey_x,50]],reduce_payment : [[F.toObject(Alice_pubKey[0]),150],[Bob_pubKey_x,50]]}); 
        
        //we record the payment they get and spend
        const Bob_getpay = w[2];
        const Chris_getpay = w[4];
        const Alice_spend = w[2];
        const Bob_spend = w[4];
    
        const leaf_input = {
            //we put the previous transaction list to the cirucit that generate new merkle leaf
            //[who][account_location][original balance][payment]
            add_list: [[Bob_pubKey_x, 3, 50, Bob_getpay],[Chris_pubKey_x, 5, 100, Chris_getpay]],
            minus_list: [[Alice_pubKey_x, 1, 200, Alice_spend],[Bob_pubKey_x, 3, 50, Bob_spend]]
        }

        //the real systeam doesn't contain this step
        //this is use for making sure new merkle leaf is correct
        const input2 = {
            pubkey: [Alice_pubKey_x,Bob_pubKey_x, Chris_pubKey_x],
            balance: [50, 150, 150]
        }

        const w2 = await make_merkle_leaf.calculateWitness(input2, true);

        const w3 = await update_merkle_leaf.calculateWitness(leaf_input, true);

        //so we can know that new merkle leaf is base on the correct balance
        await update_merkle_leaf.assertOut(w3, {new_leaf : [[3 ,w2[2]], [5, w2[3]], [1, w2[1]], [3, w2[2]]]});  
    });
});
