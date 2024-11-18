## Deploy

### Export single contract file

```sh
npx hardhat flatten <dir> > fileName
```

### How To Create vedao-deployer-key.json

1. Export private key from your wallet.
2. Create a new file
   ```
   vim key.txt
   ```
   copy your private key to the <key.txt> file
3. Using GETH
   ```
   geth account import ./key.txt
   ```
   - you need type your password
   - type again your password
4. Get your keystore file by geth

   ```
   geth account list
   ```

   you can get your keystore path looks like 'UTC--2023-03-30T09-02-44.842583000Z--4cf2ee6f44c53931b52bdbce3a15f123bf073162'  
   (note:this is an example)

5. Move your keystore to this project root folder & Rename the keystore file to "vedao-deployer-key.json"
