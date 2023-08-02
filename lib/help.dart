import 'package:flutter/material.dart';

class HelpText extends StatelessWidget {
  const HelpText({super.key, required this.text});
  final String text;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            text,
            style: optionStyle,
          ),
        )
      ],
    );
  }
}

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child:
            const Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Spacer(),
          HelpText(
            text:
                'Para utilizar o aplicativo é necessário conectar dois aparelhos (WiFi-Direct, Bluetooth, Wifi, rede de celular).',
          ),
          Spacer(),
          HelpText(
            text:
                'Depois de conectados, ambos aparelhos clicam no botão "Abrir microfone".',
          ),
          Spacer(),
          HelpText(
            text:
                'Em seguida, um dos aparelhos clica em  "Criar uma sala" e o outro clica em "entrar na sala".',
          ),
          Spacer(),
          HelpText(
            text: 'Pronto. Ao terminar de usar, clique em "Desligar".',
          ),
          Spacer(),
          HelpText(
            text:
                'No momento o aplicativo está disponível apenas para Android.',
          ),
          Spacer(),
        ]));
  }
}
