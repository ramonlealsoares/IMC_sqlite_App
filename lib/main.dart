import 'package:flutter/material.dart';
import 'package:imc_app/database_helper.dart';

void main() {
  runApp(MyApp());
}

class IMC {
  String nome;
  double peso;
  double altura;

  IMC({required this.nome, required this.peso, required this.altura});
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Calculadora IMC'),
        ),
        body: IMCForm(),
      ),
    );
  }
}

class IMCForm extends StatefulWidget {
  @override
  _IMCFormState createState() => _IMCFormState();
}

class _IMCFormState extends State<IMCForm> {
  TextEditingController nomeController = TextEditingController();
  TextEditingController pesoController = TextEditingController();
  TextEditingController alturaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            controller: nomeController,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(labelText: 'Nome'),
          ),
          TextField(
            controller: pesoController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Peso (kg)'),
          ),
          TextField(
            controller: alturaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Altura (m)'),
          ),
          SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () => calcularIMC(context),
            child: Text('Calcular IMC'),
          ),
        ],
      ),
    );
  }

  void calcularIMC(BuildContext context) async {
    String nome = nomeController.text;
    String pesoText = pesoController.text;
    String alturaText = alturaController.text;

    if (nome.isEmpty || pesoText.isEmpty || alturaText.isEmpty) {
      exibirErro(context, "Por favor, preencha todos os campos.");
      return;
    }

    double peso = double.tryParse(pesoText) ?? 0.0;
    double altura = double.tryParse(alturaText) ?? 0.0;

    IMC imc = IMC(nome: nome, peso: peso, altura: altura);

    // Salvar no SQLite
    await DatabaseHelper.instance.insertIMC(imc.nome, imc.peso);

    setState(() {
      exibirResultado(context, imc);
    });
  }

  void exibirErro(BuildContext context, String mensagem) {
    AlertDialog alert = AlertDialog(
      title: Text('Erro'),
      content: Text(mensagem),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Fechar'),
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> exibirResultado(BuildContext context, IMC imc) async {
    double resultado = calcularIMCValor(imc);
    String nivelIMC = obterNivelIMC(resultado);

    // Carregar do SQLite
    List<Map<String, dynamic>> rows =
        await DatabaseHelper.instance.queryAllRows();

    List<String> resultados = [
      'Nome: ${imc.nome}',
      'Peso: ${imc.peso} kg',
      'Altura: ${imc.altura} m',
      'IMC: ${resultado.toStringAsFixed(2)}',
      'Nível de IMC: $nivelIMC',
    ];

    // Adicione os resultados do SQLite
    for (var row in rows) {
      resultados.add('Dados Salvos: ${row['nome']}, ${row['peso']} kg');
    }

    AlertDialog alert = AlertDialog(
      title: Text('Resultado do IMC'),
      content: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: resultados.map((result) => Text(result)).toList(),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Fechar'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  String obterNivelIMC(double imc) {
    if (imc < 16) {
      return "Magreza grave";
    } else if (imc >= 16 && imc < 17) {
      return "Magreza moderada";
    } else if (imc >= 17 && imc < 18.5) {
      return "Magreza leve";
    } else if (imc >= 18.5 && imc < 25) {
      return "Saudável";
    } else if (imc >= 25 && imc < 30) {
      return "Sobrepeso";
    } else if (imc >= 30 && imc < 35) {
      return "Obesidade grau I";
    } else if (imc >= 35 && imc < 40) {
      return "Obesidade grau II (severa)";
    } else {
      return "Obesidade grau III (mórbida)";
    }
  }

  double calcularIMCValor(IMC imc) {
    return imc.peso / (imc.altura * imc.altura);
  }
}
