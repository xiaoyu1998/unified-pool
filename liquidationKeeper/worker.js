import { parentPort } from 'worker_threads';

parentPort.on('message', (message) => {
    console.log('Message received: ' + message);
    parentPort.postMessage({data: 'hi from the worker'});
});