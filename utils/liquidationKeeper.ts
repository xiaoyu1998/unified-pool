import fs from 'fs';
import path from 'path';

//libraries
export class Mutex {
    private _locking: Promise<void> = Promise.resolve();
    private _locked: boolean = false;

    // The lock method returns a promise that resolves with an unlock function.
    lock(): Promise<() => void> {
        let begin: (unlock: () => void) => void = (unlock) => {};

        // Append a new promise to the _locking chain.
        this._locking = this._locking.then(() => {
            return new Promise(begin);
        });

        return new Promise<void>((res) => {
            begin = () => {
                this._locked = true; // Set locked status to true
                res();
            };
        }).then(() => {
            return () => {
                this._locked = false; // Set locked status to false
                begin(); // Resolve the next promise in the chain
            };
        });
    }

    // The dispatch method ensures the function fn is executed within the lock.
    async dispatch<T>(fn: (() => T | Promise<T>)): Promise<T> {
        const unlock = await this.lock(); // Acquire the lock
        try {
            return await Promise.resolve(fn()); // Execute the function
        } finally {
            unlock(); // Release the lock
        }
    }
}

const liquidationAccountsFilepath = path.join(__dirname, '..', '..', `.liquidation-accounts-${process.env.HARDHAT_NETWORK}.json`)

// Define a function to read JSON file
export function readAccounts(): any {
  if (fs.existsSync(liquidationAccountsFilepath)) {
      const data = fs.readFileSync(liquidationAccountsFilepath, 'utf-8');
      return JSON.parse(data);
  }

  return []
}

// Define a function to write JSON file
export function writeAccounts(accounts: any): void {
    fs.writeFileSync(liquidationAccountsFilepath, JSON.stringify(accounts, null, 2));
}