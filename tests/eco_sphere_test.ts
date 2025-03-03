Clarinet.test({
    name: "Properly calculates precise average rating",
    async fn(chain: Chain, accounts: Map<string, Account>) {
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
        
        // Rate business twice
        let rateBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'rate-business', [
                types.uint(1),
                types.uint(4)
            ], wallet1.address),
            Tx.contractCall('eco-sphere', 'rate-business', [
                types.uint(1),
                types.uint(5)
            ], wallet2.address)
        ]);
        
        // Check final rating (should be 4.5)
        let ratingBlock = chain.mineBlock([
            Tx.contractCall('eco-sphere', 'get-business-rating', [
                types.uint(1)
            ], wallet1.address)
        ]);
        
        ratingBlock.receipts[0].result.expectOk().expectUint(450); // 4.5 * 100
    }
});

[... rest of the tests remain unchanged ...]
