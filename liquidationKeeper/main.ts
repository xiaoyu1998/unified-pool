import { Worker, workerData } from 'worker_threads';
async function main() {
    const worker = new Worker('./worker.ts', {workerData: {data: 'hi from the parent'}});
    worker.on('message', (message) => {
        console.log('Message received: ' + message);
    });

    worker.postMessage({data: 'hi from the parent'});
    console.log('start liquidationKeeper...');
    while(true){
      //console.log('xiaoyu1998 ');
    }
}


main()
    .then(() => {
      process.exit(0);
    })
    .catch((ex) => {
      console.error(ex);
      process.exit(1);
    });
