import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/price_data.dart';

class NordpoolService {
  final String baseUrl = 'https://sahkohinta-api.fi/api/v1';

  Future<List<PriceData>> fetchPriceData() async {
    return fetchPriceDataForDate(DateTime.now());
  }

  Future<List<PriceData>> fetchPriceDataForDate(DateTime date) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateString = dateFormat.format(date);

    final url =
        Uri.parse('$baseUrl/halpa?tunnit=24&tulos=haja&aikaraja=$dateString');

    print('API Request URL: $url');

    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}');
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<PriceData> prices = [];

        for (var item in jsonData) {
          prices.add(PriceData.fromJson(item));
        }
        print('Data parsing successful, ${prices.length} prices found.');
        return prices;
      } else if (response.statusCode == 204) {
        // No content available for the requested date
        print('No price data available for date: $dateString');
        return [];
      } else {
        print('API Error Response Body (non-200): ${response.body}');
        throw Exception('Failed to fetch price data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API request or parsing: $e');
      throw Exception('Failed to fetch price data: $e');
    }
  }

  Future<List<PriceData>> fetchPriceDataWithDateRange(
      DateTime startDate, DateTime endDate) async {
    final dateFormat = DateFormat('yyyy-MM-dd');
    final startString = dateFormat.format(startDate);
    final endString = dateFormat.format(endDate);

    // For date ranges, use the format startDate_endDate with time
    final aikaraja = '${startString}T00:00_${endString}T23:59';

    final url =
        Uri.parse('$baseUrl/halpa?tunnit=48&tulos=haja&aikaraja=$aikaraja');

    print('API Request URL with Date Range: $url');

    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}');
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<PriceData> prices = [];

        for (var item in jsonData) {
          prices.add(PriceData.fromJson(item));
        }
        print('Data parsing successful, ${prices.length} prices found.');
        return prices;
      } else if (response.statusCode == 204) {
        print('No price data available for given range');
        // Try to get at least today's data if range fails
        return await fetchPriceDataForDate(startDate);
      } else {
        print('API Error Response Body (non-200): ${response.body}');
        throw Exception('Failed to fetch price data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API request or parsing: $e');
      // Fallback to today's data
      try {
        return await fetchPriceDataForDate(startDate);
      } catch (fallbackError) {
        throw Exception('Failed to fetch price data: $e');
      }
    }
  }

  // Simple method to get current day's cheapest hours
  Future<List<PriceData>> fetchTodaysCheapestHours({int hours = 24}) async {
    final today = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final dateString = dateFormat.format(today);

    final url = Uri.parse(
        '$baseUrl/halpa?tunnit=$hours&tulos=haja&aikaraja=$dateString');

    print('API Request URL for today\'s cheapest hours: $url');

    try {
      final response = await http.get(url);
      print('API Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('API Response Body: ${response.body}');
        final List<dynamic> jsonData = jsonDecode(response.body);
        List<PriceData> prices = [];

        for (var item in jsonData) {
          prices.add(PriceData.fromJson(item));
        }
        print('Data parsing successful, ${prices.length} prices found.');
        return prices;
      } else if (response.statusCode == 204) {
        print('No price data available for today');
        return [];
      } else {
        print('API Error Response Body (non-200): ${response.body}');
        throw Exception('Failed to fetch price data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during API request or parsing: $e');
      throw Exception('Failed to fetch price data: $e');
    }
  }
}
