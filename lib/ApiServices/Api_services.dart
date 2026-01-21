import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../provider/Auth_provider/Auth_provider.dart';


class ApiService {
  static const String baseUrl = 'https://api.afaqmis.com/api';

  Future<Map<String, dynamic>> get(String endpoint, BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Authorization': 'Bearer ${authProvider.token}',
        'Content-Type': 'application/json',
      },
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> data,
      BuildContext context,
      ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Authorization': 'Bearer ${authProvider.token}',
        'Content-Type': 'application/json',
      },
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired or invalid
      throw Exception('Authentication failed');
    } else {
      throw Exception('API Error: ${response.statusCode}');
    }
  }
}