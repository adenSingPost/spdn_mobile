import 'package:flutter/material.dart';
import '../models/misdelivery.dart';
import '../pages/transactions_edit_page/misdelivery_page.dart';
import '../pages/transactions_edit_page/masterdoor_page.dart';
import '../pages/transactions_edit_page/return_mailbox_page.dart';
import '../../services/transaction.dart'; // Assume the correct service is used for data

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _searchQuery = '';
  bool isLoading = true;
  List<MisdeliveryTransaction> misdeliveries = [];

  @override
  void initState() {
    super.initState();
    loadMisdeliveryData();
  }

  void loadMisdeliveryData() async {
    final data = await TransactionService.fetchMisdeliveryTransactions(context); // Fetch data from the service
    setState(() {
      misdeliveries = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Transactions'),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Misdelivery'),
              Tab(text: 'Masterdoor'),
              Tab(text: 'Return Mailbox'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTabContent('Misdelivery'),
            _buildTabContent('Masterdoor'),
            _buildTabContent('Return Mailbox'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(String tabName) {
    if (tabName == 'Misdelivery') {
      if (isLoading) {
        return Center(child: CircularProgressIndicator());
      }

    final filtered = misdeliveries
        .where((tx) => tx.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
        .reversed
        .toList();


      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search $tabName',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final tx = filtered[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: Icon(Icons.local_post_office, color: Colors.deepPurple),
                    title: Text(tx.displayTitle),
                    subtitle: Text('Block: ${tx.blockNumber} | ${tx.date.split("T")[0]}'),
                    trailing: Text(tx.postalCode),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MisdeliveryPage(
                          transaction: tx,
                          onSave: (_) {},
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Placeholder for other tabs with dummy search (Masterdoor, Return Mailbox)
    final dummyTransactions = [
      {'title': '$tabName #1001', 'date': '2025-04-15', 'amount': '\$25.00'},
      {'title': '$tabName #1002', 'date': '2025-04-14', 'amount': '\$45.00'},
    ];

    final filteredDummy = dummyTransactions.where((tx) {
      return tx['title']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Search $tabName',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredDummy.length,
            itemBuilder: (context, index) {
              final tx = filteredDummy[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(Icons.receipt, color: Colors.deepPurple),
                  title: Text(tx['title']!),
                  subtitle: Text(tx['date']!),
                  trailing: Text(tx['amount']!, style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => _editTransaction(tx, index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _editTransaction(Map<String, String> tx, int index) {
    final title = tx['title']!;
    Widget destinationPage;

    if (title.toLowerCase().startsWith('misdelivery')) {
      destinationPage = MisdeliveryPage(
        transaction: MisdeliveryTransaction(
          mainDraftId: int.parse(tx['id'] ?? '0'),
          blockNumber: tx['blockNumber'] ?? '',
          postalCode: tx['postalCode'] ?? '',
          date: tx['date'] ?? '',
          misdeliveries: [], // Empty list for dummy data
        ),
        onSave: (_) {},
      );
    } else if (title.toLowerCase().startsWith('masterdoor')) {
      destinationPage = MasterDoorPage(
        postalCode: title,
        buildingNumber: '',
        onSave: (_) {},
      );
    } else if (title.toLowerCase().startsWith('return mailbox')) {
      destinationPage = ReturnMailboxChecklist(
        postalCode: title,
        buildingNumber: '',
        onSave: (_) {},
      );
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destinationPage),
    );
  }
}
