const chai = require("chai");
const path = require("path");
const wasm_tester = require("circom_tester").wasm;

const buildEddsa = require("circomlibjs").buildEddsa;
const buildBabyjub = require("circomlibjs").buildBabyjub;

const assert = chai.assert;

describe("after verify the transactions, use the result to rollup the new merkle leaf in UTXO way", function () {
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
        creat_message= await wasm_tester(path.join(__dirname, "test_circuit", "make_message.circom"));
        creat_test= await wasm_tester(path.join(__dirname, "test_circuit", "generate_leaf.circom"));
        update_leaf1= await wasm_tester(path.join(__dirname, "test_circuit", "update_leaf1.circom"));
        update_leaf2= await wasm_tester(path.join(__dirname, "test_circuit", "update_leaf2.circom"));
        rollup= await wasm_tester(path.join(__dirname, "test_circuit", "rollup.circom"));
        generate_leaf= await wasm_tester(path.join(__dirname, "test_circuit", "generate_leaf.circom"));
    });

    //this can be offer by bank
    const Alice_leaf_x="14300473964652011667050036391184662120521850930008164866589723675210657273755";
    const Alice_leaf_y="15497696423712032308821927760076543460883898784900168212404324272807389173452";
    const Bob_leaf_x="6673469457275726045665263634272671784275163661542286658106586149008685066633";
    const Bob_leaf_y="11953960145478372707268796818907269555481351742592604938852578426728246321167 ";
    const Alice_account_path=["18933334234117846673710878366312967447563874849912882306082985997953914408621",
        "15304123031794042892089670997043915742377006021656574090336323413885690017679","6488673646603647518705268581653658946519613576881584684249384467682521545402"];
    const Bob_account_path=["6844113909430542275611179983591105767070224029420610030856480815580942745395",
        "13761629597891660867219406965685130224221984273307079266383372207634242393068","6488673646603647518705268581653658946519613576881584684249384467682521545402"];
    const Chris_account_path=["13363749953045294108525919356271695915647673160159901210996868748815387250468",
        "597954442698209419274850708003643658045635445641904311813607827595157416207","3945603201662712780116976217010028808097124193349821260965764013213095921796"];


    it("Alice transfer 150 to Bob , and Chris transfer 75 to Alice, make a root that contain the transactions", async () => {

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
        message2 = await creat_message.calculateWitness({ in : [1,5,100,75,1,Alice_leaf_x,Alice_leaf_y] }, true);
        const msg2 = F.e(message2[1]);
        const Chris_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090006");
        const Chris_pubKey = eddsa.prv2pub(Chris_prvKey);
        const signature2 = eddsa.signPoseidon(Chris_prvKey, msg2);
        assert(eddsa.verifyPoseidon(msg2, signature2, Chris_pubKey));

        const Bob_prvKey = Buffer.from("0001020304050607080900010203040506070809000102030405060708090004");
        const Bob_pubKey = eddsa.prv2pub(Bob_prvKey);
    
        const input = {
            Ax: [F.toObject(Alice_pubKey[0]), F.toObject(Chris_pubKey[0])],
            Ay: [F.toObject(Alice_pubKey[1]), F.toObject(Chris_pubKey[1])],
            R8x: [F.toObject(signature1.R8[0]), F.toObject(signature2.R8[0])],
            R8y: [F.toObject(signature1.R8[1]), F.toObject(signature2.R8[1])],
            S: [signature1.S, signature2.S],
            m: [[1,1,200,150,3,Bob_leaf_x,Bob_leaf_y] , [1,5,100,75,1,Alice_leaf_x,Alice_leaf_y]],
            root: "21333424320790798199537135111871549301647283106813857717242381729307787374324",
            path_element: [Alice_account_path,Chris_account_path],
            reciever_path_element: [Bob_account_path,Alice_account_path]
        };
    
        const w = await circuit.calculateWitness(input, true);
    
        await circuit.assertOut(w, {reduce_payment_list : [[1,125],[5,25]], add_payment_list : [[3,150],[1,0]]});
    
        const Alice_new_balance = w[2];
        const Chris_new_balance = w[4];

        const input2 ={
            minus_list : [[1, F.toObject(Alice_pubKey[0]), F.toObject(Alice_pubKey[1]), Alice_new_balance], [5, F.toObject(Chris_pubKey[0]), F.toObject(Chris_pubKey[1]), Chris_new_balance]]
        };

        //we use the result of last template (the list shows who's balance become how much, and who get how much transfer)
        //as the input of update_leaf1, to generate the new merkle leaf
        const w2 = await update_leaf1.calculateWitness(input2, true);

        const transfer_to_Bob = w[6];
        const transfer_to_Alice = w[8];

        //in update_leaf2 we put the previous out put of update_leaf1 as Alice's merkle leaf
        const input3 ={
            old_leaf: [[F.toObject(Bob_pubKey[0]), F.toObject(Bob_pubKey[1]), Bob_leaf_x, Bob_leaf_y],[F.toObject(Chris_pubKey[0]), F.toObject(Chris_pubKey[1]), w2[1], w2[2]]],
            add_list: [[3,transfer_to_Bob],[1,transfer_to_Alice]]
        }

        const w3 = await update_leaf2.calculateWitness(input3, true);

        //this doesn't exist in the real project, I just want to make sure new merkle leaf had been generate as I expect
        const input4 ={
            pkx: [F.toObject(Alice_pubKey[0]), F.toObject(Chris_pubKey[0]), F.toObject(Bob_pubKey[0])],
            pky: [F.toObject(Alice_pubKey[1]), F.toObject(Chris_pubKey[1]), F.toObject(Bob_pubKey[1])],
            balance: [125,25,200]
        }

        const w4 = await generate_leaf.calculateWitness(input4, true);

        //w2 = sender = Alice , Crise
        //w3 = reciever = Bob , Alice
        const Alice_new_leaf_x = w2[2];
        const Alice_new_leaf_y = w2[3];
        const Chris_new_leaf_x = w2[5];
        const Chris_new_leaf_y = w2[6];
        const Bob_new_leaf_x = w3[2];
        const Bob_new_leaf_y = w3[3];

        //so wee can see the new merkle leaf is correct
        await generate_leaf.assertOut (w4, {x: [Alice_new_leaf_x, Chris_new_leaf_x, Bob_new_leaf_x],
             y: [Alice_new_leaf_y, Chris_new_leaf_y, Bob_new_leaf_y]});

        //and we take the new merkle leaf and the previous leaf that hadn't been change to do the rollup
        const input5 ={
            leaf_does_not_change: [[0,"6133462658069289938552243565294459806607083123641378826494830125024336713238","15209879288162627918272161991557056639280477145183971734371387380210495311430"],
                [2,"8671843092520824408411448241209876058256139303796715049488440864857748726348","3960292033989074090607275118719879514530370396734821785613848378443831651479"],
                [4,"5512011304913244723232781181387873619522626135512962915274060411975418920048","17660704989219315431036325550759212173226239915796951978599127486930229561626"],
                [6,"14287879566189231737161561113515785913920928063395708232419314762980906135576","11239671312378224716585753020534368464590839873041919300792626479675919679635"],
                [7,"15274404789518487592205307530774394799962615655840859832765958493940776087559","6844675312637260987413440100280854375281384708553311247166513506338532832440"]    
            ],
            update_leaf: [[1,Alice_new_leaf_x,Alice_new_leaf_y],[5,Chris_new_leaf_x,Chris_new_leaf_y],[3,Bob_new_leaf_x,Bob_new_leaf_y]]
        }

        const w5 = await rollup.calculateWitness(input5, true);

        //in the final we get the new root of merkle tree
        const new_root = w5[1];
    });
});