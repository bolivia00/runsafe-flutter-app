import 'package:flutter/material.dart';
import 'package:runsafe/services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedRoute = '2 km';
  final List<String> _routes = ['2 km', '3 km'];
  // 1. Criamos uma instância do nosso serviço para poder usá-lo.
  final StorageService _storageService = StorageService();

  // 2. Criamos a função que será chamada quando o usuário clicar em "Revogar".
  void _revokeConsentAndRestart() async {
    // Primeiro, chamamos o serviço para apagar o consentimento salvo.
    await _storageService.revokeUserConsent();
    
    // Depois, reiniciamos o app, voltando para a tela de Splash.
    // O pushAndRemoveUntil garante que o usuário não consiga "voltar" para a Home.
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // 3. Adicionamos um novo argumento para a rota no main.dart
  // para que a tela de Splash seja a rota inicial.
  // Vamos ajustar o main.dart a seguir.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Início'),
        // 4. Adicionamos um ícone de "configurações" na barra de título.
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Ao clicar, mostramos um diálogo de confirmação.
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
                          Navigator.of(context).pop(); // Fecha o diálogo
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