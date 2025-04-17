import 'package:flutter/material.dart';
import '../models/misdelivery.dart';
import '../models/masterdoor.dart';
import '../models/return_mailbox.dart';
import '../pages/transactions_edit_page/misdelivery_page.dart';
import '../pages/transactions_edit_page/masterdoor_page.dart';
import '../pages/transactions_edit_page/return_mailbox_page.dart';
import '../services/transaction.dart'; // Assume the correct service is used for data

class TransactionsPage extends StatefulWidget {
  @override
  _TransactionsPageState createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String _searchQuery = '';
  bool isLoading = true;
  List<MisdeliveryTransaction> misdeliveries = [];
  List<MasterdoorTransaction> masterdoors = [];
  List<ReturnMailboxTransaction> returnMailboxes = [];

  @override
  void initState() {
    super.initState();
    loadTransactionData();
  }

  void loadTransactionData() async {
    setState(() {
      isLoading = true;
    });
    
    final misdeliveryData = await TransactionService.fetchMisdeliveryTransactions(context);
    final masterdoorData = await TransactionService.fetchMasterdoorTransactions(context);
    final returnMailboxData = await TransactionService.fetchReturnMailboxTransactions(context);
    
    setState(() {
      misdeliveries = misdeliveryData;
      masterdoors = masterdoorData;
      returnMailboxes = returnMailboxData;
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
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    List<dynamic> transactions = [];
    String titleProperty = '';
    String subtitleProperty = '';
    String trailingProperty = '';
    IconData leadingIcon = Icons.receipt;
    Color iconColor = Colors.deepPurple;
    
    if (tabName == 'Misdelivery') {
      transactions = misdeliveries;
      titleProperty = 'displayTitle';
      subtitleProperty = 'date';
      trailingProperty = 'postalCode';
      leadingIcon = Icons.local_post_office;
    } else if (tabName == 'Masterdoor') {
      transactions = masterdoors;
      titleProperty = 'getDisplayTitle';
      subtitleProperty = 'date';
      trailingProperty = 'postalCode';
      leadingIcon = Icons.door_front_door;
    } else if (tabName == 'Return Mailbox') {
      transactions = returnMailboxes;
      titleProperty = 'getDisplayTitle';
      subtitleProperty = 'date';
      trailingProperty = 'postalCode';
      leadingIcon = Icons.mail_outline;
    }

    final filtered = transactions.where((tx) {
      String title = '';
      if (titleProperty == 'displayTitle') {
        title = tx.displayTitle;
      } else if (titleProperty == 'getDisplayTitle') {
        title = tx.getDisplayTitle();
      }
      return title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList().reversed.toList();

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
              String title = '';
              if (titleProperty == 'displayTitle') {
                title = tx.displayTitle;
              } else if (titleProperty == 'getDisplayTitle') {
                title = tx.getDisplayTitle();
              }
              
              // Format date and time
              String dateTime = '';
              if (subtitleProperty == 'date') {
                final dateParts = tx.date.split("T");
                if (dateParts.length > 1) {
                  final date = dateParts[0];
                  final time = dateParts[1].substring(0, 5); // Get HH:MM
                  dateTime = '$date $time';
                } else {
                  dateTime = tx.date;
                }
              }
              
              String trailing = '';
              if (trailingProperty == 'postalCode') {
                trailing = tx.postalCode;
              }
              
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Icon(leadingIcon, color: iconColor),
                  title: Text(title),
                  subtitle: Text(dateTime),
                  trailing: Text(trailing),
                  onTap: () => _editTransaction(tx, tabName),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _editTransaction(dynamic tx, String tabName) {
    Widget destinationPage;

    if (tabName == 'Misdelivery') {
      destinationPage = MisdeliveryPage(
        transaction: tx,
        onSave: (_) {},
      );
    } else if (tabName == 'Masterdoor') {
      destinationPage = MasterDoorPage(
        postalCode: tx.postalCode,
        buildingNumber: tx.buildingNumber,
        onSave: (_) {},
      );
    } else if (tabName == 'Return Mailbox') {
      destinationPage = ReturnMailboxChecklist(
        postalCode: tx.postalCode,
        buildingNumber: tx.buildingNumber,
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
