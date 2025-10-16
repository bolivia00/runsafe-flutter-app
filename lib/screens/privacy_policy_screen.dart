import 'package:flutter/material.dart';
import 'package:runsafe/screens/home_screen.dart';

// 1. Tivemos que transformar o Widget em um "StatefulWidget"
// para que ele possa "lembrar" se a caixa foi marcada ou não.
class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  // 2. Criamos uma variável para guardar o estado do checkbox.
  // Ela começa como "false" (desmarcada).
  bool _isChecked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade e Consentimento'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uso da Localização',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Para mapear suas rotas e fornecer alertas de segurança, o RunSafe precisa acessar a localização do seu dispositivo. Você pode negar essa permissão e inserir suas rotas manualmente.'),
                    const SizedBox(height: 24),
                    Text(
                      'LGPD e Seus Dados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                        'Respeitamos a sua privacidade. Seus dados de localização são utilizados exclusivamente para as funcionalidades do aplicativo e não são compartilhados com terceiros sem o seu consentimento explícito. Você pode gerenciar suas permissões a qualquer momento nas configurações do seu dispositivo.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Adicionamos o Checkbox.
            // Ele está dentro de um "CheckboxListTile" para ficar mais bonito.
            CheckboxListTile(
              title: const Text("Li e concordo com os termos."),
              value: _isChecked,
              onChanged: (bool? value) {
                // Quando o usuário clica, nós atualizamos o estado.
                setState(() {
                  _isChecked = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading, // Coloca a caixa na frente do texto
            ),
            
            const SizedBox(height: 16),

            ElevatedButton(
              // 4. A mágica acontece aqui!
              // Se _isChecked for true, a função onPressed é ativada.
              // Se for false, passamos "null", o que DESABILITA o botão automaticamente.
              onPressed: _isChecked
                  ? () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  : null, // Botão desabilitado se a caixa não estiver marcada
              child: const Text('Entendi e Concordo'),
            ),
          ],
        ),
      ),
    );
  }
}