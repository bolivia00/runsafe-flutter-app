import 'package:flutter/material.dart';
import 'package:runsafe/services/storage_service.dart';
import 'package:runsafe/widgets/app_drawer.dart'; // <-- 1. IMPORTAMOS O NOVO WIDGET

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedRoute = '2 km';
  final List<String> _routes = ['2 km', '3 km'];
  final StorageService _storageService = StorageService();

  void _revokeConsentAndRestart() async {
    await _storageService.revokeUserConsent();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Revogar Consentimento'),
                    content: const Text(
                        'Você tem certeza que deseja revogar seu consentimento? Você será levado ao início do aplicativo.'),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      TextButton(
                        child: const Text('Confirmar'),
                        onPressed: _revokeConsentAndRestart,
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      // 2. ADICIONAMOS O DRAWER AQUI
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primeiros Passos',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text('Escolha uma rota curta para começar:'),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedRoute,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRoute = newValue;
                        });
                      },
                      items:
                          _routes.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Defina seu objetivo semanal:'),
                    const TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Ex: 10 km',
                        suffix: Text('km'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                // Lógica para iniciar a corrida será adicionada aqui
              },
              icon: const Icon(Icons.directions_run),
              label: const Text('Iniciar Corrida'),
            ),
          ],
        ),
      ),
    );
  }
}