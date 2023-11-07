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
        circuit = await wasm_tester(path.join(__dirname, "transaction.circom"));
        creat_message= await wasm_tester(path.join(__dirname, "make_message.circom"));
    });

    it("Alice have 200, she pay 100 to Bob , 50 to Chris", async () => {

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
        const Bob_pubKey_x = F.toObject(Bob_pubKey[0]);

        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const Chris_pubKey_x = F.toObject(Chris_pubKey[0]);

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
        //do what : 0 = withdraw, 1 = pay , 2 = save money
        let message1;
        message1 = await creat_message.calculateWitness({ in : [1,1,200,100,3,Bob_pubKey_x,50] }, true);
        const msg1 = F.e(message1[1]);
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,1,200,50,5,Chris_pubKey_x,100] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Alice_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Alice_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Alice_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Alice_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,100,3,Bob_pubKey_x,50], [1,1,200,50,5,Chris_pubKey_x,100]],
            root: "3652006791074245341020691209164424051782923244431348363960678455191886138263",
            path_element: [["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"]],
            reciever_path_element:[["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["2195283773519661462237754398261011259690524503682308555976902945904944128550","10763015501225546336671529484009936927811817407799068279554347677670247018881","14770585617228618795027130141265691945484501340838439114116037752024033203021"]]
        };

        const w = await circuit.calculateWitness(input, true);

        await circuit.assertOut(w, {add_payment : [[Bob_pubKey_x,100],[Chris_pubKey_x,50]],reduce_payment : [[F.toObject(Alice_pubKey[0]),150],[F.toObject(Alice_pubKey[0]),150]]});  
    });

    it("transaction is same as before, but Chris is not in the merkle tree (or some necessary information is wrong), so only Bob get payment, and Alice balance only minus 100(payment to Bob)", async () => {

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
        const Bob_pubKey_x = F.toObject(Bob_pubKey[0]);

        //I change Chris_prvKey from 0001020304050607080900010203040506070809000102030405060708090006 to 0001020304050607080900010203040506070809000102030405060708090016
        //you can also try to change other thing, like account location or balance
        //so Chris_pubKey is wrong
        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090016");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const Chris_pubKey_x = F.toObject(Chris_pubKey[0]);

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
        let message1;
        message1 = await creat_message.calculateWitness({ in : [1,1,200,100,3,Bob_pubKey_x,50] }, true);
        const msg1 = F.e(message1[1]);
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,1,200,50,5,Chris_pubKey_x,100] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Alice_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Alice_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Alice_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Alice_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,100,3,Bob_pubKey_x,50], [1,1,200,50,5,Chris_pubKey_x,100]],
            root: "3652006791074245341020691209164424051782923244431348363960678455191886138263",
            path_element: [["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"]],
            reciever_path_element:[["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["2195283773519661462237754398261011259690524503682308555976902945904944128550","10763015501225546336671529484009936927811817407799068279554347677670247018881","14770585617228618795027130141265691945484501340838439114116037752024033203021"]]
        };

        const w = await circuit.calculateWitness(input, true);
        //so Chris didn't get payment, and Alice didn't lost her balance too
        await circuit.assertOut(w, {add_payment : [[Bob_pubKey_x,100],[Chris_pubKey_x,0]],reduce_payment : [[F.toObject(Alice_pubKey[0]),100],[F.toObject(Alice_pubKey[0]),100]]});  
    });

    it("Alice withdraw 150, and Bob want to pay 150 to Chris, but his balance isn't enough", async () => {

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
        let message1;
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const Alice_pubKey_x = F.toObject(Alice_pubKey[0]);
        message1 = await creat_message.calculateWitness({ in : [0,1,200,150,1,Alice_pubKey_x,200] }, true);
        const msg1 = F.e(message1[1]);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
        const Bob_pubKey_x = F.toObject(Bob_pubKey[0]);

        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const Chris_pubKey_x = F.toObject(Chris_pubKey[0]);

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,3,50,150,5,Chris_pubKey_x,100] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Bob_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Bob_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Bob_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Bob_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[0,1,200,150,1,Alice_pubKey_x,200], [1,3,50,150,5,Chris_pubKey_x,100]],
            root: "3652006791074245341020691209164424051782923244431348363960678455191886138263",
            path_element: [["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"]],
            reciever_path_element:[["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
            ["2195283773519661462237754398261011259690524503682308555976902945904944128550","10763015501225546336671529484009936927811817407799068279554347677670247018881","14770585617228618795027130141265691945484501340838439114116037752024033203021"]]
        };

        const w = await circuit.calculateWitness(input, true);

        //Alice reduce 150 in her account after she withdraw, Bob and Chris didn't be changed, because Bob's balance isn't enough for transaction 
        await circuit.assertOut(w, {add_payment : [[Alice_pubKey_x,0],[Chris_pubKey_x,0]],reduce_payment : [[Alice_pubKey_x,150],[Bob_pubKey_x,0]]});  
    });

    it("Alice save 150 to her account , and Bob want to forgery he had 500 in his account to pay 150 to Chris, but his balance is only 50", async () => {

        //[do what][sender account location][sender_balance][payment][reciever_location][reciever_pubkey_x][reciever_balance]
        let message1;
        const Alice_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090002");
        const Alice_pubKey = eddsa.prv2pub(Alice_prvKey);
        const Alice_pubKey_x = F.toObject(Alice_pubKey[0]);
        message1 = await creat_message.calculateWitness({ in : [2,1,200,150,1,Alice_pubKey_x,200] }, true);
        const msg1 = F.e(message1[1]);
        const signature1 = eddsa.signPoseidon(Alice_prvKey, msg1);
        assert(eddsa.verifyPoseidon(msg1, signature1, Alice_pubKey));

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
        const Bob_pubKey_x = F.toObject(Bob_pubKey[0]);

        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const Chris_pubKey_x = F.toObject(Chris_pubKey[0]);

        let message2;
        message2 = await creat_message.calculateWitness({ in : [1,3,500,150,5,Chris_pubKey_x,100] }, true);
        const msg2 = F.e(message2[1]);
        const signature2 = eddsa.signPoseidon(Bob_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Bob_pubKey));

        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Bob_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Bob_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[2,1,200,150,1,Alice_pubKey_x,200], [1,3,500,150,5,Chris_pubKey_x,100]],
            root: "3652006791074245341020691209164424051782923244431348363960678455191886138263",
            path_element: [["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
                ["186129652502907230370585859517825505847502827602816544549944012938722783694","21833454772156288579467829406088364751976084002162676267761930524856725521519","18095833703250244146569772865128181271125227844483579668624625852622174157459"]],
            reciever_path_element:[["1547136941649459928781666757941075310353070680911397485729242414873043921177","12157040028110623134419413019251871054790537181705644841859458739731078622195","18095833703250244146569772865128181271125227844483579668624625852622174157459"],
            ["2195283773519661462237754398261011259690524503682308555976902945904944128550","10763015501225546336671529484009936927811817407799068279554347677670247018881","14770585617228618795027130141265691945484501340838439114116037752024033203021"]]
        };

        const w = await circuit.calculateWitness(input, true);

        //Alice reduce balance for 150 (300-150) after she withdraw, Bob and Chris didn't be changed, because Bob's balance isn't enough for transaction 
        await circuit.assertOut(w, {add_payment : [[Alice_pubKey_x,300],[Chris_pubKey_x,0]],reduce_payment : [[Alice_pubKey_x,150],[Bob_pubKey_x,0]]});  
    });
});
