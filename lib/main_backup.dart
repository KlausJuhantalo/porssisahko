import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'services/nordpool_service.dart';
import 'models/price_data.dart';

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
      _fetchData();    });
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
        print('Tänään: ${todayData.length} hintatietoa');      } catch (e) {
        print('Tämän päivän tietojen haku epäonnistui: $e');
      }

      // Try to get tomorrow's data (may not be available until ~15:00)      try {
        final tomorrowData = await nordpoolService.fetchPriceDataForDate(tomorrow);
        if (tomorrowData.isNotEmpty) {
          allData.addAll(tomorrowData);
          hasTomorrowData = true;
          print('✅ Huomenna: ${tomorrowData.length} hintatietoa - SAATAVILLA!');
        }
      } catch (e) {
        print('Huomisen tietojen haku epäonnistui (normaalia ennen klo 15): $e');
      }

      // If no data at all, try yesterday as fallback
      if (allData.isEmpty) {
        try {
          final yesterday = today.subtract(Duration(days: 1));
          final yesterdayData = await nordpoolService.fetchPriceDataForDate(yesterday);
          allData.addAll(yesterdayData);
          print('Käytetään eilisen tietoja: ${yesterdayData.length} hintatietoa');
        } catch (e) {
          print('Eilisen tietojen haku epäonnistui: $e');        }
      }

      if (allData.isNotEmpty) {
        allData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        setState(() {
          priceDataList = allData;
          _currentPriceData = _findCurrentPrice(allData);
        });
      } else {
        setState(() {
          _errorMessage = 'Hintatietoja ei ole saatavilla tällä hetkellä. Huomisen hinnat päivittyvät yleensä klo 15:00 jälkeen.';
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
  String _getDataRangeText() {
    if (priceDataList.isEmpty) return '';
    
    final firstTime = priceDataList.first.timestamp;
    final lastTime = priceDataList.last.timestamp;
    final now = DateTime.now();
    
    final firstDate = DateFormat('dd.MM.yyyy').format(firstTime);
    final lastDate = DateFormat('dd.MM.yyyy').format(lastTime);
    final todayDate = DateFormat('dd.MM.yyyy').format(now);
    final tomorrowDate = DateFormat('dd.MM.yyyy').format(now.add(Duration(days: 1)));
    
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
        return 'Hinnat: $firstDate (${ priceDataList.length} tuntia)';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(
                    child: Text(_errorMessage, style: TextStyle(color: Colors.red)))
                : priceDataList.isEmpty
                    ? const Center(child: Text('Hinnatietoja ei saatavilla.'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,                          children: [
                            // Current price card
                            Card(
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  children: [
                                    Text(
                                      _currentPriceData != null
                                          ? 'Nykyinen hinta: ${_currentPriceData!.price.toStringAsFixed(2)} snt/kWh @ ${DateFormat('HH:mm').format(_currentPriceData!.timestamp.toLocal())}'
                                          : 'Hintatietoja ei saatavilla',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getDataRangeText(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Lowest and highest price cards
                            Row(
                              children: [
                                Expanded(
                                  child: Card(
                                    elevation: 3,
                                    color: Colors.green.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Icon(Icons.arrow_downward, color: Colors.green, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            'ALIN HINTA',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _findLowestPrice(priceDataList) != null
                                                ? '${_findLowestPrice(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                                : '---',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _findLowestPrice(priceDataList) != null
                                                ? DateFormat('HH:mm').format(_findLowestPrice(priceDataList)!.timestamp.toLocal())
                                                : '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Card(
                                    elevation: 3,
                                    color: Colors.red.shade50,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        children: [
                                          Icon(Icons.arrow_upward, color: Colors.red, size: 20),
                                          const SizedBox(height: 4),
                                          Text(
                                            'YLIN HINTA',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.red.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _findHighestPrice(priceDataList) != null
                                                ? '${_findHighestPrice(priceDataList)!.price.toStringAsFixed(2)} snt/kWh'
                                                : '---',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _findHighestPrice(priceDataList) != null
                                                ? DateFormat('HH:mm').format(_findHighestPrice(priceDataList)!.timestamp.toLocal())
                                                : '',
                                            style: TextStyle(
                                              fontSize: 12,
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
                                      currentPrice: _currentPriceData),
                                ),
                              ),
                            ),
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

  const PriceChart({Key? key, required this.prices, this.currentPrice})
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
            padding: const EdgeInsets.all(16.0),                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: true),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 35,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < prices.length) {                              final price = prices[index];
                              final hour = DateFormat('HH').format(price.timestamp.toLocal());
                              
                              // Show date indicator at the start of each day
                              if (index == 0 || (index > 0 && 
                                  DateFormat('dd').format(price.timestamp.toLocal()) != 
                                  DateFormat('dd').format(prices[index-1].timestamp.toLocal()))) {
                                final isToday = _isToday(price.timestamp);
                                final isTomorrow = _isTomorrow(price.timestamp);
                                String dayLabel = '';
                                if (isToday) {
                                  dayLabel = 'Tänään\n';
                                } else if (isTomorrow) {
                                  dayLabel = 'Huomenna\n';
                                } else {
                                  dayLabel = '${DateFormat('dd.MM').format(price.timestamp)}\n';
                                }
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    '$dayLabel$hour',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: isToday || isTomorrow ? FontWeight.bold : FontWeight.normal,
                                      color: isToday ? Colors.blue.shade700 : 
                                             isTomorrow ? Colors.green.shade700 : Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              } else {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(hour, style: const TextStyle(fontSize: 10)),
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
                            0.5,                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) => Colors.black.withOpacity(0.8),
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final index = barSpot.x.toInt();
                            if (index >= 0 && index < prices.length) {
                              final price = prices[index];
                              final priceText = '${price.price.toStringAsFixed(2)} snt/kWh';
                              final timeText = DateFormat('HH:mm').format(price.timestamp.toLocal());
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
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.shade300,
                        Colors.blue,
                        Colors.red.shade300
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
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
                        }

                        // Color by price level
                        final price = prices[index];
                        final minPrice = prices
                            .map((p) => p.price)
                            .reduce((a, b) => a < b ? a : b);
                        final maxPrice = prices
                            .map((p) => p.price)
                            .reduce((a, b) => a > b ? a : b);
                        final normalized =
                            (price.price - minPrice) / (maxPrice - minPrice);

                        Color dotColor;
                        if (normalized < 0.3) {
                          dotColor = Colors.green;
                        } else if (normalized > 0.7) {
                          dotColor = Colors.red;
                        } else {
                          dotColor = Colors.blue;
                        }

                        return FlDotCirclePainter(
                          radius: 4,
                          color: dotColor,
                          strokeWidth: 1,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.1),
                          Colors.blue.withOpacity(0.05),
                          Colors.red.withOpacity(0.1),
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
        // Price list
        Expanded(
          flex: 1,
          child: Container(
            height: 200,
            child: ListView.builder(
              itemCount: prices.length,
              itemBuilder: (context, index) {
                final price = prices[index];
                final isCurrentPrice = currentPrice != null &&
                    price.timestamp == currentPrice!.timestamp;

                return Card(
                  color: isCurrentPrice ? Colors.blue.shade100 : null,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                    ),                    subtitle: Text(
                      _getDateLabel(price.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: _isToday(price.timestamp) ? FontWeight.w600 : FontWeight.normal,
                        color: _isToday(price.timestamp) ? Colors.blue.shade700 : 
                               _isTomorrow(price.timestamp) ? Colors.green.shade700 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],    );
  }

  String _getDateLabel(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final priceDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
    
    if (priceDate == today) {
      return 'Tänään ${DateFormat('dd.MM').format(timestamp)}';
    } else if (priceDate == tomorrow) {
      return 'Huomenna ${DateFormat('dd.MM').format(timestamp)}';
    } else {
      return DateFormat('dd.MM.yyyy').format(timestamp);
    }
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
}
