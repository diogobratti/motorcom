import 'package:flutter/material.dart';

class Author extends StatelessWidget {
  const Author({super.key, required this.name, required this.imagePath});
  final String name;
  final String imagePath;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Image(height: 150, width: 150, image: AssetImage(imagePath)),
        Flexible(
          child: Text(
            name,
            style: optionStyle,
          ),
        )
      ],
    );
  }
}

class AboutUsText extends StatelessWidget {
  const AboutUsText({super.key, required this.text});
  final String text;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 15, fontWeight: FontWeight.bold);

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

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child:
            const Column(mainAxisAlignment: MainAxisAlignment.start, children: [
          Spacer(),
          AboutUsText(
            text:
                'Este aplicativo surgiu de uma necessidade sentida pelo Rodrigo em suas andanças por aí. Ele sentia falta de um aplicativo para conversar com o carona sem a necessidade de Internet. Ao conversar com Diogo, o mesmo resolveu fazer um aplicativo para solucionar esse problema.',
          ),
          Spacer(),
          AboutUsText(
            text:
                'Este aplicativo permanecerá sem propaganda! Se puder e quiser ajudar, aceitamos PIX como contribuição. A chave é dbratti@gmail.com',
          ),
          Spacer(),
          Author(
            name: 'Diogo Bratti - Desenvolvedor',
            imagePath: 'assets/images/diogo.jpeg',
          ),
          Spacer(),
          Author(
            name: 'Rodrigo Cristofolini',
            imagePath: 'assets/images/rodrigo.jpg',
          ),
          Spacer(),
        ]));
  }
}
