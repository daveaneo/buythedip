// node -r dotenv/config scripts/periodic_bot.js dotenv_config_path=.env
// sudo systemctl start <service>
// /etc/systemd/system/<service_name>
//////////SERVICE FILE
//[Unit]
//Description=This will be a a process to respawn a file.
//[Service]
//User=ubuntu
//WorkingDirectory=/home/ubuntu/babydogebridge/scripts
//ExecStart=/usr/bin/node -r dotenv/config /home/ubuntu/babydogebridge/scripts/api.js dotenv_config_path=/home/ubuntu/babydogebridge/.env
//Restart=always
//RestartSec=10
//[Install]
//WantedBy=multi-user.target
/////////END SERVICE FILE

const fs = require('fs')
//const qs = require('qs');
const Web3 = require('web3');
//var axios = require('axios');
const BuyTheDip = require('./../build/contracts/BuyTheDipNFT.json');
require('dotenv').config({path: __dirname + '/.env'});
const btd_address = "0x14D9aE25843088CBA97cE25941AE430DfAa33A3f";
const VERBOSE = false;

console.log('address: ', BuyTheDip.address)

process.exit(0);

BuyTheDip.address = btd_address;

var options = {
    timeout: 30000, // ms

//    // Useful if requests result are large
//    clientConfig: {
//      maxReceivedFrameSize: 100000000,   // bytes - default: 1MiB
//      maxReceivedMessageSize: 100000000, // bytes - default: 8MiB
//    },

    // Enable auto reconnection
    reconnect: {
        auto: true,
        delay: 5000, // ms
        maxAttempts: 5,
        onTimeout: false
    }
};


console.log('WATCHER_BOT_PRIVATE_KEY:')
console.log(process.env.WATCHER_BOT_PRIVATE_KEY);

//const blockChain = new Web3(process.env.ENDPOINT_WSS_BSC_TESTNET, options);
//const {address: admin} = blockChain.eth.accounts.wallet.add(process.env.WATCHER_BOT_PRIVATE_KEY);
const blockChain = new Web3(process.env.ENDPOINT_WSS_ETH_TESTNET, options);
const {address: admin} = blockChain.eth.accounts.wallet.add(process.env.WATCHER_BOT_PRIVATE_KEY);

console.log("Initiating periodic_bot...");
const apiUrl = 'https://slack.com/api';

const send = async (message) => {
};


const storeMessage = async (nonce, message) => {
    fs.readFile('storedMessages.json', 'utf8', function readFileCallback(err, data){
        var obj;
        if (err || !data.includes("messages")){
            console.log("File does not exist or badly formatted.");
            console.log(err);
            // create empty object
            obj = {   messages: []    };
        } else {
            obj = JSON.parse(data); //now it an object
        }
        obj.messages.push({nonce: nonce, message:message}); //add some data
        json = JSON.stringify(obj); //convert it back to json
        fs.writeFile('storedMessages.json', json, 'utf8', function writeFileCallback(err){
            if(err){
                console.log(err);
            }
        });
    });
};

//const post = async (args) => {
//    axios.post(`${apiUrl}/chat.postMessage`, qs.stringify(args));
//};

//const bscBlock = 0;
//const ethBlock = 0;


const btd = new blockChain.eth.Contract(
    BuyTheDip.abi,
    BuyTheDip.address
);


const checkUpkeep = async () => {
    const tx = btd.methods.checkUpkeepView(0);

    try {
        const [gasPrice, gasCost] = await Promise.all([
            blockChain.eth.getGasPrice(),
            tx.estimateGas({from: admin}),
        ]);

        const data = tx.encodeABI();
        const result = await blockChain.eth.call({
            from: admin,
            to: btd.options.address,
            data,
            gas: gasCost,
            gasPrice
        }); // .then(res => console.log(`res: ${res}`))

//        console.log(result);

        if(result==true){
            console.log("Status returned true. Upkeep needed.")
            performUpkeep();
        }
        else {
            console.log("Status returned false. Exiting.")
            process.exit(0);
        }

    } catch (error) {
        errorObj = new Error(error);
        console.log(error);
        console.log(errorObj.message)
    };
};


const performUpkeep = async () => {
    console.log("\n----Performing upkeep-----")
    const tx = btd.methods.performUpkeep(0);

    try {
        const [gasPrice, gasCost] = await Promise.all([
            blockChain.eth.getGasPrice(),
            tx.estimateGas({from: admin}),
        ]);

        const data = tx.encodeABI();
        const receipt = await blockChain.eth.sendTransaction({
            from: admin,
            to: btd.options.address,
            data,
            gas: gasCost,
            gasPrice
        });

        console.log(receipt);

        // todo --not sure if status works this way
        if(receipt.status==true){
            console.log("Upkeep performed.")
        }
        else {
            console.log("Status returned false. Exiting.")
        }
        process.exit(0);
    } catch (error) {
        errorObj = new Error(error);
        console.log(error);
        console.log(errorObj.message)
        process.exit(1);
    };


};

checkUpkeep();