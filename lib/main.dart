import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _urlController = TextEditingController();
  String _errorMessage = '';

  // Проверка валидности URL
  bool _isValidUrl(String url) {
    final urlPattern = r'^(https?:\/\/)?[\w-]+(\.[\w-]+)+[/#?]?.*$';
    return RegExp(urlPattern).hasMatch(url);
  }

  void _navigateToLoadingScreen(String url) {
    if (_isValidUrl(url)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingScreen(url: url),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Некорректный URL!';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Введите API URL:'),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://example.com/api',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _navigateToLoadingScreen(_urlController.text);
              },
              child: const Text('Start counting process'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatefulWidget {
  final String url;

  const LoadingScreen({super.key, required this.url});

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startCalculations();
  }

  // Симуляция расчётов
  void _startCalculations() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        _progress = i.toDouble();
        if (_progress == 100) {
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _sendResultsToServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final url = 'https://flutter.webspark.dev/api/';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'progress': _progress,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        final List<dynamic> pathData = jsonResponse['path'];

        final List<List<int>> path = pathData.map((coord) {
          return [coord[0] as int, coord[1] as int];
        }).toList();

        setState(() {
          _isLoading = false;
        });
        _navigateToNextScreen(path);
      } else {
        setState(() {
          _errorMessage = 'Ошибка: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка при отправке данных: $e';
        _isLoading = false;
      });
    }
  }

  void _navigateToNextScreen(List<List<int>> path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SuccessScreen(path: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'All calculations have finished, you can send your results to server',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 20),
            Text(
              '${_progress.toInt()}%',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(
              value: _progress / 100,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isLoading ? null : _sendResultsToServer,
              child: const Text('Send results to server'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SuccessScreen extends StatelessWidget {
  final List<List<int>> path;

  const SuccessScreen({super.key, required this.path});

  String formatPath() {
    return path.map((coords) => '(${coords[0]},${coords[1]})').join(' -> ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result list screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              formatPath(),
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
