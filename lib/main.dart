import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON decoding

void main() {
  runApp(const WeatherApp());
}

// Main application widget
class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cool Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily:
            'Inter', // Assuming 'Inter' font is available or a system default
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const WeatherHomePage(),
      debugShowCheckedModeBanner: false, // Remove debug banner
    );
  }
}

// Home page of the weather application
class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  String _currentLocation = 'London'; // Default location
  WeatherInfo? _weatherData; // Nullable to indicate loading state
  bool _isLoading = false; // To show loading indicator
  // YOUR OPENWEATHERMAP API KEY IS ADDED HERE
  final String _openWeatherApiKey = '597fa56cb51add16ed0a96921d48d105';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData(
      _currentLocation,
    ); // Fetch initial weather data for default location
  }

  // Function to fetch weather data from OpenWeatherMap API
  Future<void> _fetchWeatherData(String location) async {
    setState(() {
      _isLoading = true; // Set loading to true
      _currentLocation = location; // Update current location for display
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$location&appid=$_openWeatherApiKey&units=metric',
        ),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Extract relevant data from the API response
        final int temperature = data['main']['temp'].round();
        final String condition =
            data['weather'][0]['description']; // Using description for more detail
        final String iconCode =
            data['weather'][0]['icon']; // Icon code from OpenWeatherMap

        // --- START: CORRECT TIMEZONE CALCULATION ---
        final int unixTimestamp = data['dt']; // Time of data calculation, UTC
        final int timezoneOffsetSeconds =
            data['timezone']; // Shift in seconds from UTC

        // Calculate the local DateTime for the location
        final DateTime utcTime = DateTime.fromMillisecondsSinceEpoch(
          unixTimestamp * 1000,
          isUtc: true,
        );
        final DateTime locationTime = utcTime.add(
          Duration(seconds: timezoneOffsetSeconds),
        );
        // --- END: CORRECT TIMEZONE CALCULATION ---

        // Determine icon and gradient colors based on condition/icon code
        IconData icon = Icons.help_outline;
        List<Color> gradientColors = [Colors.grey, Colors.blueGrey];

        if (iconCode.contains('01')) {
          // Clear sky (day/night)
          icon = Icons.wb_sunny;
          gradientColors = [
            const Color(0xFFFFD700),
            const Color(0xFFFFA500),
          ]; // Orange/Yellow
        } else if (iconCode.contains('02')) {
          // Few clouds
          icon = Icons.cloud_queue;
          gradientColors = [
            const Color(0xFF89CFF0),
            const Color(0xFFADD8E6),
          ]; // Light Blue
        } else if (iconCode.contains('03') || iconCode.contains('04')) {
          // Scattered/Broken clouds
          icon = Icons.cloud;
          gradientColors = [
            const Color(0xFFB0C4DE),
            const Color(0xFFD3D3D3),
          ]; // Light Steel Blue/Light Grey
        } else if (iconCode.contains('09') || iconCode.contains('10')) {
          // Shower rain / Rain
          icon = Icons.umbrella;
          gradientColors = [
            const Color(0xFF4682B4),
            const Color(0xFF6A5ACD),
          ]; // Steel Blue/Purple
        } else if (iconCode.contains('11')) {
          // Thunderstorm
          icon = Icons.thunderstorm_outlined;
          gradientColors = [
            const Color(0xFF6A5ACD),
            const Color(0xFF483D8B),
          ]; // Purple/Indigo
        } else if (iconCode.contains('13')) {
          // Snow
          icon = Icons.ac_unit;
          gradientColors = [
            const Color(0xFFADD8E6),
            const Color(0xFFE0FFFF),
          ]; // Light Blue/Azure
        } else if (iconCode.contains('50')) {
          // Mist
          icon = Icons.foggy;
          gradientColors = [
            const Color(0xFFB0C4DE),
            const Color(0xFFD3D3D3),
          ]; // Light Steel Blue/Light Grey
        }

        // --- START: USE locationTime FOR ALL DATE/TIME FORMATTING ---
        final String date =
            '${_getDayOfWeek(locationTime.weekday)}, ${locationTime.day}${_getDaySuffix(locationTime.day)} ${_getMonth(locationTime.month)}';

        // Corrected time formatting for 12-hour format with AM/PM using locationTime
        final int hour = locationTime.hour;
        final int displayHour = hour % 12 == 0 ? 12 : hour % 12;
        final String ampm = hour >= 12 ? 'pm' : 'am';
        final String time =
            '$displayHour:${locationTime.minute.toString().padLeft(2, '0')}$ampm';
        // --- END: USE locationTime FOR ALL DATE/TIME FORMATTING ---

        setState(() {
          _weatherData = WeatherInfo(
            date: date,
            time: time,
            location: data['name'], // Use location name from API
            temperature: temperature,
            icon: icon,
            condition: _capitalizeFirstLetter(
              condition,
            ), // Capitalize first letter of condition
            gradientColors: gradientColors,
          );
        });
      } else if (response.statusCode == 404) {
        // Location not found
        _showErrorDialog(
          'Location Not Found',
          'Could not find weather data for "$location". Please try a different location.',
        );
        setState(() {
          _weatherData = WeatherInfo.defaultData;
        });
      } else {
        // Other API errors
        _showErrorDialog(
          'API Error',
          'Failed to load weather data: ${response.statusCode} - ${response.body}',
        );
        setState(() {
          _weatherData = WeatherInfo.defaultData;
        });
      }
    } catch (e) {
      // Network or parsing errors
      _showErrorDialog(
        'Network Error',
        'An error occurred while fetching data: $e',
      );
      setState(() {
        _weatherData = WeatherInfo.defaultData;
      });
    } finally {
      setState(() {
        _isLoading =
            false; // Always set loading to false after request completes
      });
    }
  }

  // Helper to show a dialog message
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper functions for date formatting
  String _getDayOfWeek(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF333333), // Dark background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  onSubmitted: _fetchWeatherData, // Call API fetch on submit
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search location...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    prefixIcon: const Icon(Icons.search, color: Colors.white),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15.0,
                      horizontal: 20.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display the main weather card or loading indicator
              _isLoading
                  ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                  : _weatherData != null
                  ? WeatherCard(
                    weather: _weatherData!,
                    isMainCard: true, // Indicates this is the primary card
                  )
                  : const SizedBox.shrink(), // Or an empty state widget
              const SizedBox(height: 20),
              // Display additional weather cards (e.g., for different times of day)
              // These are static for demonstration, but could be dynamic from API
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // These cards will still use dummy data as they are not tied to the search
                  WeatherCard(weather: WeatherInfo.londonMorning),
                  WeatherCard(weather: WeatherInfo.newYorkDay),
                  WeatherCard(weather: WeatherInfo.tokyoEvening),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Data model for weather information
class WeatherInfo {
  final String date;
  final String time;
  final String location;
  final int temperature;
  final IconData icon;
  final String condition;
  final List<Color> gradientColors;

  const WeatherInfo({
    required this.date,
    required this.time,
    required this.location,
    required this.temperature,
    required this.icon,
    required this.condition,
    required this.gradientColors,
  });

  // Dummy weather data examples (can be used for other cards or fallbacks)
  static const WeatherInfo londonMorning = WeatherInfo(
    date: 'Mon, May 24', // Simplified for static display
    time: '6:00am',
    location: 'London',
    temperature: 10,
    icon: Icons.cloud_queue,
    condition: 'Cloudy',
    gradientColors: [Color(0xFF89CFF0), Color(0xFFADD8E6)], // Light Blue
  );

  static const WeatherInfo newYorkDay = WeatherInfo(
    date: 'Mon, May 24',
    time: '9:00am',
    location: 'New York',
    temperature: 17,
    icon: Icons.wb_sunny,
    condition: 'Sunny',
    gradientColors: [Color(0xFFFFD700), Color(0xFFFFA500)], // Orange/Yellow
  );

  static const WeatherInfo tokyoEvening = WeatherInfo(
    date: 'Mon, May 24',
    time: '3:00pm',
    location: 'Tokyo',
    temperature: 19,
    icon: Icons.thunderstorm_outlined,
    condition: 'Stormy',
    gradientColors: [Color(0xFF6A5ACD), Color(0xFF483D8B)], // Purple/Indigo
  );

  static const WeatherInfo defaultData = WeatherInfo(
    date: 'Today',
    time: 'Now',
    location: 'Unknown',
    temperature: 15,
    icon: Icons.help_outline,
    condition: 'N/A',
    gradientColors: [Colors.grey, Colors.blueGrey], // Grey fallback
  );
}

// Reusable widget for displaying a single weather card
class WeatherCard extends StatelessWidget {
  final WeatherInfo weather;
  final bool isMainCard; // To make the main card slightly larger

  const WeatherCard({
    super.key,
    required this.weather,
    this.isMainCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:
          isMainCard
              ? MediaQuery.of(context).size.width * 0.9
              : MediaQuery.of(context).size.width * 0.28,
      height: isMainCard ? 300 : 180,
      margin: EdgeInsets.symmetric(horizontal: isMainCard ? 0 : 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        gradient: LinearGradient(
          colors: weather.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isMainCard
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.start,
          children: [
            // Date and Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  weather.date,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMainCard ? 16 : 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  weather.time,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMainCard ? 20 : 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Location
            Text(
              weather.location,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: isMainCard ? 18 : 10,
              ),
            ),
            if (isMainCard)
              const Spacer(), // Pushes content apart only for main card
            // Weather Icon and Temperature
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  weather.icon,
                  color: Colors.white,
                  size: isMainCard ? 80 : 30,
                ),
                Text(
                  '${weather.temperature}°',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMainCard ? 70 : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (isMainCard)
              const Spacer(), // Pushes content apart only for main card
            // Day of the week (or condition for smaller cards)
            Text(
              isMainCard
                  ? weather.condition
                  : weather.date.split(
                    ',',
                  )[0], // Show condition for main, day for small
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isMainCard ? 24 : 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            // Small placeholder icons at the bottom
            if (isMainCard)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSmallIcon(Icons.air, 'Wind'),
                    _buildSmallIcon(Icons.water_drop, 'Humidity'),
                    _buildSmallIcon(Icons.umbrella, 'Rain'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Helper to build small icons for the main card
  Widget _buildSmallIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
        ),
      ],
    );
  }
}
