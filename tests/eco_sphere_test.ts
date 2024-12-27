import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new business",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'register-business', [
                types.ascii("Eco Store"),
                types.ascii("A sustainable store"),
                types.ascii("ISO 14001 certified")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let getBusinessBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'get-business', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const business = getBusinessBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(business['name'], "Eco Store");
    }
});

Clarinet.test({
    name: "Can rate and verify a business",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // First register a business
        let block = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'register-business', [
                types.ascii("Eco Store"),
                types.ascii("A sustainable store"),
                types.ascii("ISO 14001 certified")
            ], wallet1.address)
        ]);
        
        // Rate the business
        let rateBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'rate-business', [
                types.uint(1),
                types.uint(5)
            ], wallet2.address)
        ]);
        
        rateBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Verify the business
        let verifyBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'verify-business', [
                types.uint(1)
            ], wallet2.address)
        ]);
        
        verifyBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Can support a business",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Register business
        let block = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'register-business', [
                types.ascii("Eco Store"),
                types.ascii("A sustainable store"),
                types.ascii("ISO 14001 certified")
            ], wallet1.address)
        ]);
        
        // Support business
        let supportBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'support-business', [
                types.uint(1),
                types.uint(1000)
            ], wallet2.address)
        ]);
        
        supportBlock.receipts[0].result.expectOk().expectBool(true);
    }
});