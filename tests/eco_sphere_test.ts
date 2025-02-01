import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Can register a new business with category",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'register-business', [
                types.ascii("Eco Store"),
                types.ascii("A sustainable store"),
                types.ascii("ISO 14001 certified"),
                types.ascii("retail")
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let getBusinessBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'get-business', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        const business = getBusinessBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(business['category'], "retail");
    }
});

Clarinet.test({
    name: "Can enable rewards and earn points",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Register business
        let block = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'register-business', [
                types.ascii("Eco Store"),
                types.ascii("A sustainable store"),
                types.ascii("ISO 14001 certified"),
                types.ascii("retail")
            ], wallet1.address)
        ]);
        
        // Enable rewards
        let enableBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'enable-rewards', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        enableBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Rate business and earn points
        let rateBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'rate-business', [
                types.uint(1),
                types.uint(5)
            ], wallet2.address)
        ]);
        
        rateBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Check points
        let pointsBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'get-user-points', [
                types.principal(wallet2.address),
                types.uint(1)
            ], wallet2.address)
        ]);
        
        pointsBlock.receipts[0].result.expectOk().expectUint(10);
    }
});
