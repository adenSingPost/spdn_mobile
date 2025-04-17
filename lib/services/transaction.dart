import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/misdelivery.dart';
import '../models/masterdoor.dart';
import '../models/return_mailbox.dart';
import '../utils/constants.dart';
import './auth_service.dart'; // Or wherever your AuthService is located
import 'package:flutter/material.dart';

class TransactionService {
  static Future<List<MisdeliveryTransaction>> fetchMisdeliveryTransactions(BuildContext context) async {
    final AuthService _authService = AuthService();

    String? validAccessToken = await _authService.getValidAccessToken(context);
    if (validAccessToken == null) {
      print('No access token available');
      return [];
    }

    final response = await http.get(
      Uri.parse('${Constants.backendUrl}/transaction/misdelivery'),
      headers: {
        'Authorization': 'Bearer $validAccessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<MisdeliveryTransaction> fetched = [];

      data.forEach((key, value) {
        print('Processing transaction:');
        print('  Key: $key');
        print('  Value: $value');
        fetched.add(MisdeliveryTransaction.fromJson(int.parse(key), value));
      });

      return fetched;
    } else {
      print('Failed to fetch misdeliveries: ${response.body}');
      return [];
    }
  }

  static Future<List<MasterdoorTransaction>> fetchMasterdoorTransactions(BuildContext context) async {
    final AuthService _authService = AuthService();

    String? validAccessToken = await _authService.getValidAccessToken(context);
    if (validAccessToken == null) {
      print('No access token available');
      return [];
    }

    final response = await http.get(
      Uri.parse('${Constants.backendUrl}/transaction/masterdoor'),
      headers: {
        'Authorization': 'Bearer $validAccessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      final List<dynamic> data = jsonDecode(response.body);
      final List<MasterdoorTransaction> fetched = [];

      for (var item in data) {
        print('Processing masterdoor transaction:');
        print('  Item: $item');
        fetched.add(MasterdoorTransaction.fromJson(item));
      }

      return fetched;
    } else {
      print('Failed to fetch masterdoor transactions: ${response.body}');
      return [];
    }
  }

  static Future<List<ReturnMailboxTransaction>> fetchReturnMailboxTransactions(BuildContext context) async {
    final AuthService _authService = AuthService();

    String? validAccessToken = await _authService.getValidAccessToken(context);
    if (validAccessToken == null) {
      print('No access token available');
      return [];
    }

    final response = await http.get(
      Uri.parse('${Constants.backendUrl}/transaction/returnmailbox'),
      headers: {
        'Authorization': 'Bearer $validAccessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print('API Response: ${response.body}');
      final List<dynamic> data = jsonDecode(response.body);
      final List<ReturnMailboxTransaction> fetched = [];

      for (var item in data) {
        print('Processing return mailbox transaction:');
        print('  Item: $item');
        fetched.add(ReturnMailboxTransaction.fromJson(item));
      }

      return fetched;
    } else {
      print('Failed to fetch return mailbox transactions: ${response.body}');
      return [];
    }
  }
}
