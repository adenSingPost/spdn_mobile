import 'package:flutter/material.dart';
import '../models/masterdoor.dart';
import '../services/transaction.dart';

class MasterdoorTransactionsPage extends StatefulWidget {
  const MasterdoorTransactionsPage({Key? key}) : super(key: key);

  @override
  State<MasterdoorTransactionsPage> createState() => _MasterdoorTransactionsPageState();
}

class _MasterdoorTransactionsPageState extends State<MasterdoorTransactionsPage> {
  List<MasterdoorTransaction> _transactions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await TransactionService.fetchMasterdoorTransactions(context);
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Masterdoor Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadTransactions,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Center(
        child: Text('No masterdoor transactions found'),
      );
    }

    return ListView.builder(
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(transaction.displayTitle),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (transaction.observation != null && transaction.observation!.isNotEmpty)
                  Text('Observation: ${transaction.observation}'),
                Text('Status: ${transaction.checklistOption}'),
                Text('Created: ${transaction.createdAt}'),
              ],
            ),
            onTap: () {
              // TODO: Navigate to transaction details page
            },
          ),
        );
      },
    );
  }
} 