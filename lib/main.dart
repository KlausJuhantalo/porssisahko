import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'services/nordpool_service.dart';
import 'models/price_data.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nordpool Sähkön Hinta',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Nordpool Sähkön Hinnat'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final NordpoolService nordpoolService = NordpoolService();
  List<PriceData> priceDataList = [];
  bool _isLoading = false;
  PriceData? _currentPriceData;
  String _errorMessage = '';
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_errorMessage.isNotEmpty) {
        final context = this.context;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    _fetchData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    // Tarkista huomisen tiedot automaattisesti joka 30 minuuttia
    _autoRefreshTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      print('Automaattinen päivitys: tarkistetaan huomisen tiedot');
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      priceDataList = [];
      _currentPriceData = null;
    });

    try {
      final today = DateTime.now();
      final tomorrow = today.add(Duration(days: 1));
      List<PriceData> allData = [];
      bool hasTomorrowData = false;

      // Try to get today's data
      try {
        final todayData = await nordpoolService.fetchPriceDataForDate(today);
        allData.addAll(todayData);
        print('Tänään: ${todayData.length} hintatietoa');
      } catch (e) {
        print('Tämän päivän tietojen haku epäonnistui: $e');
      }

      // Try to get tomorrow's data (may not be available until ~15:00)
      try {
        final tomorrowData =
            await nordpoolService.fetchPriceDataForDate(tomorrow);
        if (tomorrowData.isNotEmpty) {
          allData.addAll(tomorrowData);
          hasTomorrowData = true;
          print('✅ Huomenna: ${tomorrowData.length} hintatietoa - SAATAVILLA!');
        }
      } catch (e) {
        print(
            'Huomisen tietojen haku epäonnistui (normaalia ennen klo 15): $e');
      }

      // If no data at all, try yesterday as fallback
      if (allData.isEmpty) {
        try {
          final yesterday = today.subtract(Duration(days: 1));
          final yesterdayData =
              await nordpoolService.fetchPriceDataForDate(yesterday);
          allData.addAll(yesterdayData);
          print(
              'Käytetään eilisen tietoja: ${yesterdayData.length} hintatietoa');
        } catch (e) {
          print('Eilisen tietojen haku epäonnistui: $e');
        }
      }
      if (allData.isNotEmpty) {
        // Sort by timestamp to ensure correct order
        allData.sort((a, b) => a.timestamp.compareTo(b.timestamp));

        // DEBUG: Tulostetaan kaikki data ennen UI:n päivitystä
        print(
            '🔍 DEBUG: allData sisältää yhteensä ${allData.length} hintatietoa:');
        for (int i = 0; i < allData.length; i++) {
          final price = allData[i];
          final dateStr = DateFormat('dd.MM HH:mm').format(price.timestamp);
          print('🔍 DEBUG: [$i] $dateStr - ${price.price}¢');
        }

        setState(() {
          priceDataList = allData;
          _currentPriceData = _findCurrentPrice(allData);

          // DEBUG: Tarkistetaan, mitä tietoja on priceDataListissa
          print(
              '🔍 DEBUG: priceDataList asetettu, yhteensä ${priceDataList.length} hintatietoa');
          if (priceDataList.isNotEmpty) {
            print(
                '🔍 DEBUG: Ensimmäinen: ${DateFormat('dd.MM HH:mm').format(priceDataList.first.timestamp)}');
            print(
                '🔍 DEBUG: Viimeinen: ${DateFormat('dd.MM HH:mm').format(priceDataList.last.timestamp)}');
          }

          // Päivitetään viesti sen mukaan, onko huomisen tietoja
          if (!hasTomorrowData) {
            final currentHour = DateTime.now().hour;
            if (currentHour < 15) {
              _errorMessage =
                  'Huomisen hinnat julkaistaan yleensä klo 15:00 jälkeen. Päivitetään automaattisesti.';
            } else {
              _errorMessage =
                  'Huomisen hintoja ei vielä saatavilla. Kokeillaan uudelleen automaattisesti.';
            }
          } else {
            _errorMessage =
                ''; // Tyhjennä virheilmoitus jos huomisen tiedot löytyivät
          }
        });
      } else {
        setState(() {
          _errorMessage =
              'Hintatietoja ei ole saatavilla tällä hetkellä. Huomisen hinnat päivittyvät yleensä klo 15:00 jälkeen.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hintatietojen hakeminen epäonnistui: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  PriceData? _findCurrentPrice(List<PriceData> prices) {
    final now = DateTime.now().toLocal();
    return prices.lastWhere(
      (p) => p.timestamp.isBefore(now) || p.timestamp.isAtSameMomentAs(now),
      orElse: () => prices.first,
    );
  }

  PriceData? _findLowestPrice(List<PriceData> prices) {
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a.price < b.price ? a : b);
  }

  PriceData? _findHighestPrice(List<PriceData> prices) {
    if (prices.isEmpty) return null;
    return prices.reduce((a, b) => a.price > b.price ? a : b);
  }

  // Uudet funktiot päiväkohtaiseen hintahakuun
  PriceData? _findLowestPriceForToday(List<PriceData> prices) {
    final todayPrices =
        prices.where((price) => _isToday(price.timestamp)).toList();
    return _findLowestPrice(todayPrices);
  }

  PriceData? _findHighestPriceForToday(List<PriceData> prices) {
    final todayPrices =
        prices.where((price) => _isToday(price.timestamp)).toList();
    return _findHighestPrice(todayPrices);
  }

  PriceData? _findLowestPriceForTomorrow(List<PriceData> prices) {
    final tomorrowPrices =
        prices.where((price) => _isTomorrow(price.timestamp)).toList();
    return _findLowestPrice(tomorrowPrices);
  }

  PriceData? _findHighestPriceForTomorrow(List<PriceData> prices) {
    final tomorrowPrices =
        prices.where((price) => _isTomorrow(price.timestamp)).toList();
    return _findHighestPrice(tomorrowPrices);
  }

  bool _hasTomorrowData(List<PriceData> prices) {
    return prices.any((price) => _isTomorrow(price.timestamp));
  }

  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return priceDate == today;
  }

  bool _isTomorrow(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return priceDate == tomorrow;
  }

  String _getDataRangeText() {
    if (priceDataList.isEmpty) return '';

    final firstTime = priceDataList.first.timestamp;
    final lastTime = priceDataList.last.timestamp;
    final now = DateTime.now();

    final firstDate = DateFormat('dd.MM.yyyy').format(firstTime);
    final lastDate = DateFormat('dd.MM.yyyy').format(lastTime);
    final todayDate = DateFormat('dd.MM.yyyy').format(now);
    final tomorrowDate =
        DateFormat('dd.MM.yyyy').format(now.add(Duration(days: 1)));

    // Count hours for today and tomorrow
    int todayHours = 0;
    int tomorrowHours = 0;

    for (var price in priceDataList) {
      final priceDate = DateFormat('dd.MM.yyyy').format(price.timestamp);
      if (priceDate == todayDate) {
        todayHours++;
      } else if (priceDate == tomorrowDate) {
        tomorrowHours++;
      }
    }

    if (firstDate == lastDate) {
      // Single day data
      if (firstDate == todayDate) {
        return 'Tänään: $todayHours tuntia';
      } else if (firstDate == tomorrowDate) {
        return 'Huomenna: $tomorrowHours tuntia';
      } else {
        return 'Hinnat: $firstDate (${priceDataList.length} tuntia)';
      }
    } else {
      // Multi-day data
      String result = '';
      if (todayHours > 0) {
        result += 'Tänään: $todayHours h';
      }
      if (tomorrowHours > 0) {
        if (result.isNotEmpty) result += ' • ';
        result += 'Huomenna: $tomorrowHours h';
      }
      if (result.isEmpty) {
        result = 'Hinnat: $firstDate - $lastDate (${priceDataList.length} h)';
      }
      return result;
    }
  }

  String getDateLabel(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (priceDate == today) {
      return 'Tänään 	${DateFormat('dd.MM').format(timestamp)}';
    } else if (priceDate == tomorrow) {
      return 'Huomenna ${DateFormat('dd.MM').format(timestamp)}';
    } else {
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tietoa',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AboutPage(
                    infoMessage: _errorMessage,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : priceDataList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            _errorMessage.isNotEmpty
                                ? _errorMessage
                                : 'Hintatietoja ei saatavilla.',
                            style: TextStyle(
                                color: _errorMessage.contains('automaattisesti')
                                    ? Colors.orange
                                    : Colors.red),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Yritä uudelleen'),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current price card
                        Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8.0, horizontal: 16.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.flash_on,
                                        color: Colors.blue, size: 18),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _currentPriceData != null
                                            ? 'Nykyinen hinta: 	${_currentPriceData!.price.toStringAsFixed(2)} snt/kWh @ ${DateFormat('HH:mm').format(_currentPriceData!.timestamp.toLocal())}'
                                            : 'Hintatietoja ei saatavilla',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_currentPriceData != null)
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        tooltip: 'Kopioi hinnat',
                                        onPressed: () {
                                          final lowest =
                                              _findLowestPriceForToday(
                                                  priceDataList);
                                          final highest =
                                              _findHighestPriceForToday(
                                                  priceDataList);
                                          final current = _currentPriceData;
                                          final text = 'Sähkön hinnat tänään:\n'
                                              'Nykyinen: ${current!.price.toStringAsFixed(2)} snt/kWh @ ${DateFormat('HH:mm').format(current.timestamp.toLocal())}\n'
                                              'Alin: ${lowest != null ? lowest.price.toStringAsFixed(2) : '-'} snt/kWh @ ${lowest != null ? DateFormat('HH:mm').format(lowest.timestamp.toLocal()) : '-'}\n'
                                              'Ylin: ${highest != null ? highest.price.toStringAsFixed(2) : '-'} snt/kWh @ ${highest != null ? DateFormat('HH:mm').format(highest.timestamp.toLocal()) : '-'}';
                                          Clipboard.setData(
                                              ClipboardData(text: text));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Hinnat kopioitu leikepöydälle!')),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                            height:
                                10), // Lowest and highest price cards - päiväkohtaisten
                        Row(
                          children: [
                            // Tänään alin hinta
                            Expanded(
                              child: Card(
                                elevation: 3,
                                color: Colors.green.shade50,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_downward,
                                              color: Colors.green, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ALIN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _findLowestPriceForToday(
                                                    priceDataList) !=
                                                null
                                            ? '${_findLowestPriceForToday(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                            : '---',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _findLowestPriceForToday(
                                                    priceDataList) !=
                                                null
                                            ? DateFormat('HH:mm').format(
                                                _findLowestPriceForToday(
                                                        priceDataList)!
                                                    .timestamp
                                                    .toLocal())
                                            : '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tänään ylin hinta
                            Expanded(
                              child: Card(
                                elevation: 3,
                                color: Colors.red.shade50,
                                margin: const EdgeInsets.only(bottom: 8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.arrow_upward,
                                              color: Colors.red, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            'YLIN',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _findHighestPriceForToday(
                                                    priceDataList) !=
                                                null
                                            ? '${_findHighestPriceForToday(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                            : '---',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _findHighestPriceForToday(
                                                    priceDataList) !=
                                                null
                                            ? DateFormat('HH:mm').format(
                                                _findHighestPriceForToday(
                                                        priceDataList)!
                                                    .timestamp
                                                    .toLocal())
                                            : '',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Huomisen hinnat (vain jos saatavilla)
                        if (_hasTomorrowData(priceDataList))
                          Row(
                            children: [
                              // Huomenna alin hinta
                              Expanded(
                                child: Card(
                                  elevation: 3,
                                  color: Colors.lightGreen.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.arrow_downward,
                                            color: Colors.lightGreen, size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ALIN HUOMENNA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.lightGreen.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _findLowestPriceForTomorrow(
                                                      priceDataList) !=
                                                  null
                                              ? '${_findLowestPriceForTomorrow(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                              : '---',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _findLowestPriceForTomorrow(
                                                      priceDataList) !=
                                                  null
                                              ? DateFormat('HH:mm').format(
                                                  _findLowestPriceForTomorrow(
                                                          priceDataList)!
                                                      .timestamp
                                                      .toLocal())
                                              : '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Huomenna ylin hinta
                              Expanded(
                                child: Card(
                                  elevation: 3,
                                  color: Colors.orange.shade50,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      children: [
                                        Icon(Icons.arrow_upward,
                                            color: Colors.orange, size: 20),
                                        const SizedBox(height: 4),
                                        Text(
                                          'YLIN HUOMENNA',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _findHighestPriceForTomorrow(
                                                      priceDataList) !=
                                                  null
                                              ? '${_findHighestPriceForTomorrow(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                              : '---',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _findHighestPriceForTomorrow(
                                                      priceDataList) !=
                                                  null
                                              ? DateFormat('HH:mm').format(
                                                  _findHighestPriceForTomorrow(
                                                          priceDataList)!
                                                      .timestamp
                                                      .toLocal())
                                              : '',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Chart
                        Expanded(
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: PriceChart(
                                  prices: priceDataList,
                                  currentPrice: _currentPriceData,
                                  getDateLabel: getDateLabel),
                            ),
                          ),
                        ),
                        // Collapsible price list
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(top: 8.0),
                          child: ExpansionTile(
                            title: const Text('Näytä kaikki tuntihinnat',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            iconColor: Colors.blue,
                            collapsedIconColor: Colors.blue,
                            children: [
                              SizedBox(
                                height: 200,
                                child: ListView.builder(
                                  itemCount: priceDataList.length,
                                  itemBuilder: (context, index) {
                                    final price = priceDataList[index];
                                    final isCurrentPrice =
                                        _currentPriceData != null &&
                                            price.timestamp ==
                                                _currentPriceData!.timestamp;
                                    return Card(
                                      color: isCurrentPrice
                                          ? Colors.blue.shade100
                                          : null,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      child: ListTile(
                                        dense: true,
                                        title: Text(
                                          '${DateFormat('HH:mm').format(price.timestamp.toLocal())}: ${price.price.toStringAsFixed(2)} snt/kWh',
                                          style: TextStyle(
                                            fontWeight: isCurrentPrice
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                        subtitle: Text(
                                          getDateLabel(price.timestamp),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight:
                                                _isToday(price.timestamp)
                                                    ? FontWeight.w600
                                                    : FontWeight.normal,
                                            color: _isToday(price.timestamp)
                                                ? Colors.blue.shade700
                                                : _isTomorrow(price.timestamp)
                                                    ? Colors.green.shade700
                                                    : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60), // Add space for FAB
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchData,
        tooltip: 'Päivitä',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class PriceChart extends StatelessWidget {
  final List<PriceData> prices;
  final PriceData? currentPrice;
  final String Function(DateTime) getDateLabel;

  const PriceChart(
      {Key? key,
      required this.prices,
      this.currentPrice,
      required this.getDateLabel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (prices.isEmpty) {
      return const Center(child: Text('Ei tietoja kaaviota varten'));
    }

    return Column(
      children: [
        // Legend
        Container(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Halpa', Colors.green),
              _buildLegendItem('Keskihinta', Colors.blue),
              _buildLegendItem('Kallis', Colors.red),
              _buildLegendItem('Nykyinen', Colors.orange),
            ],
          ),
        ),

        // Chart
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < prices.length) {
                          final price = prices[index];
                          final hour = DateFormat('HH')
                              .format(price.timestamp.toLocal());

                          // Show date indicator at the start of each day
                          if (index == 0 ||
                              (index > 0 &&
                                  DateFormat('dd')
                                          .format(price.timestamp.toLocal()) !=
                                      DateFormat('dd').format(prices[index - 1]
                                          .timestamp
                                          .toLocal()))) {
                            final isToday = _isToday(price.timestamp);
                            final isTomorrow = _isTomorrow(price.timestamp);
                            String dayLabel = '';
                            if (isToday) {
                              dayLabel = 'Tänään\n';
                            } else if (isTomorrow) {
                              dayLabel = 'Huomenna\n';
                            } else {
                              dayLabel =
                                  '${DateFormat('dd.MM').format(price.timestamp)}\n';
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                '$dayLabel$hour',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: isToday || isTomorrow
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isToday
                                      ? Colors.blue.shade700
                                      : isTomorrow
                                          ? Colors.green.shade700
                                          : Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(hour,
                                  style: const TextStyle(fontSize: 10)),
                            );
                          }
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return SideTitleWidget(
                          meta: meta,
                          child: Text('${value.toStringAsFixed(1)}¢',
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: prices.length.toDouble() - 1,
                minY:
                    prices.map((p) => p.price).reduce((a, b) => a < b ? a : b) -
                        0.5,
                maxY:
                    prices.map((p) => p.price).reduce((a, b) => a > b ? a : b) +
                        0.5,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) =>
                        Colors.black.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final index = barSpot.x.toInt();
                        if (index >= 0 && index < prices.length) {
                          final price = prices[index];
                          final priceText =
                              '${price.price.toStringAsFixed(2)} snt/kWh';
                          final timeText = DateFormat('HH:mm')
                              .format(price.timestamp.toLocal());
                          return LineTooltipItem(
                            '$priceText\n$timeText',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _generateChartDataPoints(prices),
                    isCurved: true,
                    color: Colors.blue, // Base color for the line
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        // Highlight current price
                        if (currentPrice != null &&
                            index < prices.length &&
                            prices[index].timestamp ==
                                currentPrice!.timestamp) {
                          return FlDotCirclePainter(
                            radius: 8,
                            color: Colors.orange,
                            strokeWidth: 3,
                            strokeColor: Colors.white,
                          );
                        } // Color by price level
                        final price = prices[index];
                        final minPrice = prices
                            .map((p) => p.price)
                            .reduce((a, b) => a < b ? a : b);
                        final maxPrice = prices
                            .map((p) => p.price)
                            .reduce((a, b) => a > b ? a : b);
                        final normalized =
                            (price.price - minPrice) / (maxPrice - minPrice);

                        // DEBUG: Tulostetaan väritys
                        print(
                            '🎨 Hinta ${price.price}¢, norm: ${normalized.toStringAsFixed(2)}');

                        Color dotColor;
                        if (normalized < 0.3) {
                          dotColor = Colors.green;
                          print('🎨 -> Vihreä (halpa)');
                        } else if (normalized > 0.7) {
                          dotColor = Colors.red;
                          print('🎨 -> Punainen (kallis)');
                        } else {
                          dotColor = Colors.blue;
                          print('🎨 -> Sininen (keski)');
                        }
                        return FlDotCirclePainter(
                          radius: 6, // Isommat pisteet
                          color: dotColor,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.green.withOpacity(
                              0.3), // Alhaalla vihreä (alhaiset hinnat)
                          Colors.blue.withOpacity(0.2), // Keskellä sininen
                          Colors.red.withOpacity(
                              0.3), // Ylhäällä punainen (korkeat hinnat)
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _generateChartDataPoints(List<PriceData> prices) {
    return prices
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.price))
        .toList();
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  bool _isToday(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return priceDate == today;
  }

  bool _isTomorrow(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    return priceDate == tomorrow;
  }
}

// AboutPage-luokka
class AboutPage extends StatelessWidget {
  final String infoMessage;
  const AboutPage({Key? key, required this.infoMessage}) : super(key: key);

  Future<void> _launchCasaMedia() async {
    final url = Uri.parse('https://casamedia.fi');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tietoa sovelluksesta')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Huomisen hinnat -ilmoitus:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              infoMessage.isNotEmpty
                  ? infoMessage
                  : 'Huomisen hinnat julkaistaan yleensä klo 15:00 jälkeen. Päivitetään automaattisesti.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 32),
            Text('Lisätietoja:', style: TextStyle(fontWeight: FontWeight.bold)),
            InkWell(
              child: const Text('casamedia.fi',
                  style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline)),
              onTap: _launchCasaMedia,
            ),
          ],
        ),
      ),
    );
  }
}
