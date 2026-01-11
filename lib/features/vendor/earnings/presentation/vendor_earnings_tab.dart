import 'package:flutter/material.dart';

class VendorEarningsTab extends StatelessWidget {
  const VendorEarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.payments_outlined),
                title: Text('Today', style: TextStyle(fontWeight: FontWeight.w900)),
                trailing: Text('₱ 1,540', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                subtitle: Text('Placeholder — connect to payout ledger later'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.account_balance_wallet_outlined),
                title: Text('Available balance', style: TextStyle(fontWeight: FontWeight.w900)),
                trailing: Text('₱ 8,900', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                subtitle: Text('Request payout (future)'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const ListTile(
                leading: Icon(Icons.history),
                title: Text('Payout history', style: TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('Coming soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
