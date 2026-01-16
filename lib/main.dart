import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_math_fork/flutter_math.dart';
void main() {
  runApp(const MyApp());

}

/* ENUMI */
enum Kombinatorika { permutacije, variacije, kombinacije }
enum Dogodki { vsota, zmnozek,pogojna}
enum OsVrjetnost { navadna, geometrijska }
enum TipPorazdelitve { diskretna, zvezna }
enum OpisnaVnos { rocni, datoteka }
class HistoryEntry {
  final Mode mode;
  final Map<String, String> inputs;
  final String result;
  final DateTime time;

  HistoryEntry({
    required this.mode,
    required this.inputs,
    required this.result,
    required this.time,
  });

  Map<String, dynamic> toJson() => {
    'mode': mode.index,
    'inputs': inputs,
    'result': result,
    'time': time.toIso8601String(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    return HistoryEntry(
      mode: Mode.values[json['mode']],
      inputs: Map<String, String>.from(json['inputs']),
      result: json['result'],
      time: DateTime.parse(json['time']),
    );
  }
}


enum Mode {
  kombinatorika,
  dogodki,
  osVrjetnost,
  intervalZaupanja,
  opisnaStatistika,
  centralniLimitniIzrek,
  porazdelitve, // ⬅ NOVO
  zgodovina
}

enum DiskretnaPorazdelitev {
  bernoulli,
  binomska,
  poisson,
}

enum ZveznaPorazdelitev {
  normalna,
  eksponentna,
  uniformna,
}





/* APP */
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matematika',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Kombinatorika & Verjetnost'),
    );
  }
}

/* HOME PAGE */
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}

/* STATE */
class _MyHomePageState extends State<MyHomePage> {
  @override void initState() {
    super.initState();

      controllerMap = {
        // kombinatorika
        'n': nController,
        'k': kController,

        // osnovna verjetnost
        'ugodni': ugodniController,
        'vsi': vsiController,
        'dolzinaUgodni': dolzinaUgodniController,
        'dolzinaCelota': dolzinaCelotaController,

        // dogodki
        'pA': pAController,
        'pB': pBController,
        'pAB': pABController,

        // porazdelitve
        'p': pController,
        'lambda': lambdaController,
        'x': xDistController,
        'a': aController,
        'b': bController,

        // statistika
        'data': dataController,

        // CLT / normalna
        'mu': muController,
        'sigma': sigmaController,
        'nClt': nCltController,
      };



    loadHistory();
  }
  /* MODE */
  Mode mode = Mode.kombinatorika;
  int selectedPercentile = 95;
  // CLI
  final TextEditingController muController = TextEditingController();
  final TextEditingController sigmaController = TextEditingController();
  final TextEditingController nCltController = TextEditingController();
  final TextEditingController xController = TextEditingController();

  /* KOMBINATORIKA */
  final TextEditingController nController = TextEditingController();
  final TextEditingController kController = TextEditingController();
  Kombinatorika selectedKomb = Kombinatorika.permutacije;

  /* DOGODKI */
  final TextEditingController pAController = TextEditingController();
  final TextEditingController pBController = TextEditingController();
  final TextEditingController pABController = TextEditingController();
  List<TextEditingController> eventControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool showAdvancedUI = true;

  Map<String, TextEditingController> intersectionControllers = {};
  Dogodki selectedDogodek = Dogodki.vsota;
  // OSNOVNA VERJETNOST
  OsVrjetnost selectedOsVrjetnost = OsVrjetnost.navadna;
  final TextEditingController ugodniController = TextEditingController();
  final TextEditingController vsiController = TextEditingController();
  final TextEditingController dolzinaUgodniController = TextEditingController();
  final TextEditingController dolzinaCelotaController = TextEditingController();
  // INTERVALI ZAUPANJA
  final TextEditingController uspehiController = TextEditingController();
  final TextEditingController poskusiController = TextEditingController();

  // OPISNA STATISTIKA
  final TextEditingController dataController = TextEditingController();
  OpisnaVnos selectedOpisnaVnos = OpisnaVnos.rocni;
  File? selectedFile;

  //zgodovina
  List<HistoryEntry> history = [];
  late final Map<String, TextEditingController> controllerMap;
  // PORAZDELITVE
  // PORAZDELITVE
  TipPorazdelitve selectedTip = TipPorazdelitve.diskretna;
  DiskretnaPorazdelitev selectedDiskretna = DiskretnaPorazdelitev.bernoulli;
  ZveznaPorazdelitev selectedZvezna = ZveznaPorazdelitev.normalna;


  final TextEditingController pController = TextEditingController();
  final TextEditingController nDistController = TextEditingController();
  final TextEditingController kDistController = TextEditingController();
  final TextEditingController lambdaController = TextEditingController();
  final TextEditingController xDistController = TextEditingController();
  final TextEditingController aController = TextEditingController();
  final TextEditingController bController = TextEditingController();

  String result = '';
  //zgodovina
  Future<void> saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    prefs.setStringList('history', jsonList);
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList('history') ?? [];
    setState(() {
      history = jsonList
          .map((e) => HistoryEntry.fromJson(jsonDecode(e)))
          .toList();
    });
  }
  void restoreFromHistory(HistoryEntry entry) {
    setState(() {
      mode = entry.mode;
      result = entry.result;

      // Clear all controllers first (important!)
      for (final controller in controllerMap.values) {
        controller.clear();
      }

      // Restore only what exists in history
      entry.inputs.forEach((key, value) {
        if (controllerMap.containsKey(key)) {
          controllerMap[key]!.text = value;
        }
      });
    });
  }




  /* FAKULTETA */
  int factorial(int n) {
    int r = 1;
    for (int i = 1; i <= n; i++) {
      r *= i;
    }
    return r;
  }
  List<double>? parseData() {
    try {
      return dataController.text
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
    } catch (_) {
      return null;
    }
  }
  Future<void> loadTxtFile() async {
    try {
      FilePickerResult? resultPicker = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (resultPicker == null) return; // uporabnik prekliče

      File file = File(resultPicker.files.single.path!);
      String content = await file.readAsString();

      // Podpira:
      // 1, 2, 3
      // 1 2 3
      // 1\n2\n3
      content = content
          .replaceAll('\n', ',')
          .replaceAll(' ', '');

      setState(() {
        dataController.text = content.trim();
        selectedFile = file;
      });
    } catch (e) {
      setState(() {
        result = 'Napaka pri nalaganju datoteke.';
      });
    }
  }

  double median(List<double> data) {
    data.sort();
    int n = data.length;
    if (n % 2 == 1) {
      return data[n ~/ 2];
    } else {
      return (data[n ~/ 2 - 1] + data[n ~/ 2]) / 2;
    }
  }

  List<double> modus(List<double> data) {
    final Map<double, int> freq = {};
    for (var x in data) {
      freq[x] = (freq[x] ?? 0) + 1;
    }

    int maxFreq = freq.values.reduce(max);
    if (maxFreq == 1) return [];

    return freq.entries
        .where((e) => e.value == maxFreq)
        .map((e) => e.key)
        .toList();
  }
  double mean(List<double> data) {
    double sum = data.reduce((a, b) => a + b);
    return sum / data.length;
  }

  double minimum(List<double> data) {
    return data.reduce(min);
  }

  double maximum(List<double> data) {
    return data.reduce(max);
  }

  void calculateOpisnaStatistika() {
    final data = parseData();

    if (data == null || data.isEmpty) {
      setState(() => result = 'Invalid input');
      return;
    }

    final sorted = List<double>.from(data)..sort();
    final n = sorted.length;

    double avg = mean(data);
    double med = median(List.from(data));
    List<double> mod = modus(data);
    double minVal = minimum(data);
    double maxVal = maximum(data);
    double range = maxVal - minVal;

    // postopek za povprečje
    String sumProcess = data.join(' + ');
    double sum = data.reduce((a, b) => a + b);

    setState(() {
      result =
      'Opisna statistika\n'
          '=================\n\n'
          'Podatki:\n'
          '${data.join(', ')}\n\n'

          'Število podatkov:\n'
          'n = $n\n\n'

          'Aritmetična sredina (povprečje):\n'
          'x̄ = (x₁ + x₂ + ... + xₙ) / n\n'
          'x̄ = ($sumProcess) / $n\n'
          'x̄ = ${sum.toStringAsFixed(4)} / $n\n'
          'x̄ = ${avg.toStringAsFixed(4)}\n\n'

          'Mediana:\n'
          '${n.isOdd
          ? 'Ker je n liho, vzamemo srednji element.'
          : 'Ker je n sodo, vzamemo povprečje srednjih dveh elementov.'}\n'
          'Mediana = ${med.toStringAsFixed(4)}\n\n'

          'Modus:\n'
          '${mod.isEmpty ? 'Modus ne obstaja.' : mod.join(', ')}\n\n'

          'Minimum:\n'
          'min = ${minVal.toStringAsFixed(4)}\n\n'

          'Maksimum:\n'
          'max = ${maxVal.toStringAsFixed(4)}\n\n'

          'Razpon:\n'
          'R = max − min = ${maxVal.toStringAsFixed(4)} − ${minVal.toStringAsFixed(4)}\n'
          'R = ${range.toStringAsFixed(4)}';
    });

    final entry = HistoryEntry(
      mode: Mode.opisnaStatistika,
      inputs: {
        'data': dataController.text,
      },
      result: result,
      time: DateTime.now(),
    );

    setState(() {
      history.insert(0, entry);
    });

    saveHistory();
  }

  //CLI
  void calculateCLT() {
    double? mu = double.tryParse(muController.text);
    double? sigma = double.tryParse(sigmaController.text);
    int? n = int.tryParse(nCltController.text);
    double? x = double.tryParse(xController.text);

    if (mu == null || sigma == null || x == null || n == null || n <= 0 || sigma <= 0) {
      setState(() => result = 'Invalid input');
      return;
    }

    double se = sigma / sqrt(n);
    double z = (x - mu) / se;

    setState(() {
      result =
      'Centralni limitni izrek\n'
          '----------------------\n'
          'Podatki:\n'
          'μ = $mu\n'
          'σ = $sigma\n'
          'n = $n\n'
          'x = $x\n\n'
          'Koraki:\n'
          '1) Standardna napaka:\n'
          '   SE = σ / √n = $sigma / √$n = ${se.toStringAsFixed(4)}\n\n'
          '2) Z-vrednost:\n'
          '   z = (x − μ) / SE\n'
          '   z = ($x − $mu) / ${se.toStringAsFixed(4)}\n'
          '   z = ${z.toStringAsFixed(4)}';
    });


  }

// OSNOVNA VRJETNOST
  void calculateOsVrjetnost() {
    double value;

    switch (selectedOsVrjetnost) {

    /* ================= NAVADNA ================= */
      case OsVrjetnost.navadna:
        int? ugodni = int.tryParse(ugodniController.text);
        int? vsi = int.tryParse(vsiController.text);

        if (ugodni == null || vsi == null || vsi == 0 || ugodni < 0 || ugodni > vsi) {
          setState(() => result = 'Invalid input');
          return;
        }

        value = ugodni / vsi;

        final res =
            'Navadna verjetnost\n'
            '------------------\n'
            'Podatki:\n'
            'ugodnih izidov = $ugodni\n'
            'vseh izidov = $vsi\n\n'
            'Formula:\n'
            'P = ugodni / vsi\n\n'
            'Postopek:\n'
            'P = $ugodni / $vsi\n'
            'P = ${value.toStringAsFixed(4)}';

        setState(() => result = res);


        history.insert(
          0,
          HistoryEntry(
            mode: Mode.osVrjetnost,
            inputs: {
              'ugodni': ugodniController.text,
              'vsi': vsiController.text,
            },
            result: res,
            time: DateTime.now(),
          ),
        );

        saveHistory();
        break;

    /* ================= GEOMETRIJSKA ================= */
      case OsVrjetnost.geometrijska:
        double? dolzinaUgodni = double.tryParse(dolzinaUgodniController.text);
        double? dolzinaCelota = double.tryParse(dolzinaCelotaController.text);

        if (dolzinaUgodni == null ||
            dolzinaCelota == null ||
            dolzinaCelota == 0 ||
            dolzinaUgodni < 0 ||
            dolzinaUgodni > dolzinaCelota) {
          setState(() => result = 'Invalid input');
          return;
        }

        value = dolzinaUgodni / dolzinaCelota;

        final res =
            'Geometrijska verjetnost\n'
            '----------------------\n'
            'Podatki:\n'
            'ugodna dolžina = $dolzinaUgodni\n'
            'celotna dolžina = $dolzinaCelota\n\n'
            'Formula:\n'
            'P = ugodna dolžina / celotna dolžina\n\n'
            'Postopek:\n'
            'P = $dolzinaUgodni / $dolzinaCelota\n'
            'P = ${value.toStringAsFixed(4)}';

        setState(() => result = res);


        history.insert(
          0,
          HistoryEntry(
            mode: Mode.osVrjetnost,
            inputs: {
              'dolzinaUgodni': dolzinaUgodniController.text,
              'dolzinaCelota': dolzinaCelotaController.text,
            },
            result: res,
            time: DateTime.now(),
          ),
        );

        saveHistory();
        break;
    }
  }




  /* KOMBINATORIKA */
  String factorialSteps(int n) {
    if (n == 0 || n == 1) return '1';
    return List.generate(n, (i) => (n - i).toString()).join('·');
  }

  void calculateKombinatorika() {
    int? n = int.tryParse(nController.text);
    int? k = int.tryParse(kController.text);

    // Preverjanje veljavnosti n
    if (n == null || n < 0) {
      setState(() => result = 'Neveljavna vrednost n');
      return;
    }

    int value;
    String postopek = '';

    switch (selectedKomb) {

      case Kombinatorika.permutacije:
        value = factorial(n);

        postopek =
        'PERMUTACIJE\n'
            'Permutacije predstavljajo vse možne razporeditve n elementov.\n\n'
            'Formula:\n'
            'P(n) = n!\n\n'
            'Vstavljanje vrednosti:\n'
            'P($n) = $n!\n\n'
            'Izračun fakultete:\n'
            '$n! = ${factorialSteps(n)}\n\n'
            'Rezultat:\n'
            'P($n) = $value';

        break;

      case Kombinatorika.variacije:
        if (k == null || k < 0 || k > n) {
          setState(() => result = 'Neveljavna vrednost k');
          return;
        }

        value = factorial(n) ~/ factorial(n - k);

        postopek =
        'VARIACIJE\n'
            'Variacije predstavljajo število različnih zaporedij k elementov\n'
            'izmed n elementov, kjer je vrstni red pomemben.\n\n'
            'Formula:\n'
            'V(n,k) = n! / (n-k)!\n\n'
            'Vstavljanje vrednosti:\n'
            'V($n,$k) = $n! / ${n - k}!\n\n'
            'Izračun:\n'
            '(${factorialSteps(n)}) / (${factorialSteps(n - k)})\n\n'
            'Rezultat:\n'
            'V($n,$k) = $value';

        break;

      case Kombinatorika.kombinacije:
        if (k == null || k < 0 || k > n) {
          setState(() => result = 'Neveljavna vrednost k');
          return;
        }

        value = factorial(n) ~/ (factorial(k) * factorial(n - k));

        postopek =
        'KOMBINACIJE\n'
            'Kombinacije predstavljajo izbiro k elementov izmed n,\n'
            'kjer vrstni red NI pomemben.\n\n'
            'Formula:\n'
            'C(n,k) = n! / (k!(n-k)!)\n\n'
            'Vstavljanje vrednosti:\n'
            'C($n,$k) = $n! / ($k!·${n - k}!)\n\n'
            'Izračun:\n'
            '(${factorialSteps(n)}) / '
            '(${factorialSteps(k)}·${factorialSteps(n - k)})\n\n'
            'Rezultat:\n'
            'C($n,$k) = $value';

        break;
    }

    setState(() => result = postopek);

    final entry = HistoryEntry(
      mode: mode,
      inputs: {
        'n': nController.text,
        'k': kController.text,
      },
      result: result,
      time: DateTime.now(),
    );

    setState(() {
      history.insert(0, entry);
    });

    saveHistory();
  }


  // D IN Z P
  double binomska(int n, int k, double p) {
    return factorial(n) /
        (factorial(k) * factorial(n - k)) *
        pow(p, k) *
        pow(1 - p, n - k);
  }

  double poisson(int k, double lambda) {
    return pow(lambda, k) * exp(-lambda) / factorial(k);
  }

  double normalna(double x, double mu, double sigma) {
    return (1 / (sigma * sqrt(2 * pi))) *
        exp(-pow(x - mu, 2) / (2 * pow(sigma, 2)));
  }

  double eksponentna(double x, double lambda) {
    return x < 0 ? 0 : lambda * exp(-lambda * x);
  }

  double uniformna(double x, double a, double b) {
    if (x < a || x > b) return 0;
    return 1 / (b - a);
  }
  void calculatePorazdelitve() {
    double value;

    try {
      Map<String, String> inputs = {};

      /* ================= DISKRETNE ================= */
      if (selectedTip == TipPorazdelitve.diskretna) {

        /* ===== BERNOULLI ===== */
        if (selectedDiskretna == DiskretnaPorazdelitev.bernoulli) {
          double p = double.parse(pController.text);
          int x = int.parse(xDistController.text);

          value = (x == 1) ? p : (1 - p);

          result =
          'Bernoullijeva porazdelitev\n'
              '========================\n\n'
              'Formula:\n'
              'P(X = x) = pˣ · (1 − p)¹⁻ˣ\n\n'
              'Podatki:\n'
              'p = $p\n'
              'x = $x\n\n'
              'Formula z vstavljenimi podatki:\n'
              'P(X = $x) = ${p}^$x · ${(1 - p)}^${1 - x}\n\n'
              'Rezultat:\n'
              'P(X = $x) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Bernoullijeva porazdelitev opisuje en sam poskus\n'
              'z dvema možnima izidoma (uspeh ali neuspeh).';

          inputs = {
            'p': pController.text,
            'x': xDistController.text,
          };
        }

        /* ===== BINOMSKA ===== */
        else if (selectedDiskretna == DiskretnaPorazdelitev.binomska) {
          int n = int.parse(nDistController.text);
          int k = int.parse(kDistController.text);
          double p = double.parse(pController.text);

          value = binomska(n, k, p);

          result =
          'Binomska porazdelitev\n'
              '====================\n\n'
              'Formula:\n'
              'P(X = k) = C(n,k) · pᵏ · (1 − p)ⁿ⁻ᵏ\n\n'
              'Podatki:\n'
              'n = $n\n'
              'k = $k\n'
              'p = $p\n\n'
              'Formula z vstavljenimi podatki:\n'
              'P(X = $k) = C($n,$k) · $p^$k · ${(1 - p)}^${n - k}\n\n'
              'Rezultat:\n'
              'P(X = $k) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Binomska porazdelitev opisuje verjetnost\n'
              'natanko k uspehov v n neodvisnih poskusih,\n'
              'kjer je verjetnost uspeha enaka p.';

          inputs = {
            'n': nDistController.text,
            'k': kDistController.text,
            'p': pController.text,
          };
        }

        /* ===== POISSON ===== */
        else if (selectedDiskretna == DiskretnaPorazdelitev.poisson) {
          int k = int.parse(kDistController.text);
          double lambda = double.parse(lambdaController.text);

          value = poisson(k, lambda);

          result =
          'Poissonova porazdelitev\n'
              '======================\n\n'
              'Formula:\n'
              'P(X = k) = (λᵏ · e⁻ˡ) / k!\n\n'
              'Podatki:\n'
              'k = $k\n'
              'λ = $lambda\n\n'
              'Formula z vstavljenimi podatki:\n'
              'P(X = $k) = ($lambda^$k · e^-$lambda) / $k!\n\n'
              'Rezultat:\n'
              'P(X = $k) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Poissonova porazdelitev opisuje verjetnost,\n'
              'da se bo v določenem časovnem ali prostorskem\n'
              'intervalu zgodilo natanko k dogodkov.';

          inputs = {
            'k': kDistController.text,
            'lambda': lambdaController.text,
          };
        }
      }

      /* ================= ZVEZNE ================= */
      else if (selectedTip == TipPorazdelitve.zvezna) {

        /* ===== NORMALNA ===== */
        if (selectedZvezna == ZveznaPorazdelitev.normalna) {
          double x = double.parse(xDistController.text);
          double mu = double.parse(muController.text);
          double sigma = double.parse(sigmaController.text);

          if (sigma <= 0) throw Exception();

          value = normalna(x, mu, sigma);

          result =
          'Normalna porazdelitev\n'
              '====================\n\n'
              'Formula:\n'
              'f(x) = 1 / (σ√(2π)) · e^(-(x − μ)² / (2σ²))\n\n'
              'Podatki:\n'
              'x = $x\n'
              'μ = $mu\n'
              'σ = $sigma\n\n'
              'Formula z vstavljenimi podatki:\n'
              'f($x) = 1 / ($sigma√(2π)) · e^(-($x − $mu)² / (2·$sigma²))\n\n'
              'Rezultat (gostota):\n'
              'f($x) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Normalna porazdelitev opisuje zvezne\n'
              'naključne spremenljivke, kjer so vrednosti\n'
              'simetrično razporejene okoli povprečja μ.';

          inputs = {
            'x': xDistController.text,
            'mu': muController.text,
            'sigma': sigmaController.text,
          };
        }

        /* ===== EKSPONENTNA ===== */
        else if (selectedZvezna == ZveznaPorazdelitev.eksponentna) {
          double x = double.parse(xDistController.text);
          double lambda = double.parse(lambdaController.text);

          value = eksponentna(x, lambda);

          result =
          'Eksponentna porazdelitev\n'
              '=======================\n\n'
              'Formula:\n'
              'f(x) = λ · e⁻ˡˣ,  x ≥ 0\n\n'
              'Podatki:\n'
              'x = $x\n'
              'λ = $lambda\n\n'
              'Formula z vstavljenimi podatki:\n'
              'f($x) = $lambda · e^(-$lambda·$x)\n\n'
              'Rezultat (gostota):\n'
              'f($x) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Eksponentna porazdelitev opisuje čas do\n'
              'naslednjega dogodka v Poissonovem procesu.';

          inputs = {
            'x': xDistController.text,
            'lambda': lambdaController.text,
          };
        }

        /* ===== UNIFORMNA ===== */
        else if (selectedZvezna == ZveznaPorazdelitev.uniformna) {
          double x = double.parse(xDistController.text);
          double a = double.parse(aController.text);
          double b = double.parse(bController.text);

          value = uniformna(x, a, b);

          result =
          'Uniformna porazdelitev\n'
              '=====================\n\n'
              'Formula:\n'
              'f(x) = 1 / (b − a),  a ≤ x ≤ b\n\n'
              'Podatki:\n'
              'x = $x\n'
              'a = $a\n'
              'b = $b\n\n'
              'Formula z vstavljenimi podatki:\n'
              'f($x) = 1 / ($b − $a)\n\n'
              'Rezultat (gostota):\n'
              'f($x) = ${value.toStringAsFixed(6)}\n\n'
              'Razlaga:\n'
              'Uniformna porazdelitev pomeni, da so vse\n'
              'vrednosti na intervalu [a, b] enako verjetne.';

          inputs = {
            'x': xDistController.text,
            'a': aController.text,
            'b': bController.text,
          };
        }
      }

      history.insert(
        0,
        HistoryEntry(
          mode: Mode.porazdelitve,
          inputs: inputs,
          result: result,
          time: DateTime.now(),
        ),
      );

      saveHistory();

      setState(() {});
    } catch (e) {
      setState(() => result = 'Invalid input');
    }
  }





  //intervali zaupanja
  double inverseNormal(double p) {
    // p mora biti v (0,1)
    const a1 = -39.69683028665376;
    const a2 = 220.9460984245205;
    const a3 = -275.9285104469687;
    const a4 = 138.3577518672690;
    const a5 = -30.66479806614716;
    const a6 = 2.506628277459239;

    const b1 = -54.47609879822406;
    const b2 = 161.5858368580409;
    const b3 = -155.6989798598866;
    const b4 = 66.80131188771972;
    const b5 = -13.28068155288572;

    const c1 = -0.007784894002430293;
    const c2 = -0.3223964580411365;
    const c3 = -2.400758277161838;
    const c4 = -2.549732539343734;
    const c5 = 4.374664141464968;
    const c6 = 2.938163982698783;

    const d1 = 0.007784695709041462;
    const d2 = 0.3224671290700398;
    const d3 = 2.445134137142996;
    const d4 = 3.754408661907416;

    const pLow = 0.02425;
    const pHigh = 1 - pLow;

    double q, r;

    if (p < pLow) {
      q = sqrt(-2 * log(p));
      return (((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
          ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
    }

    if (p <= pHigh) {
      q = p - 0.5;
      r = q * q;
      return (((((a1 * r + a2) * r + a3) * r + a4) * r + a5) * r + a6) * q /
          (((((b1 * r + b2) * r + b3) * r + b4) * r + b5) * r + 1);
    }

    q = sqrt(-2 * log(1 - p));
    return -(((((c1 * q + c2) * q + c3) * q + c4) * q + c5) * q + c6) /
        ((((d1 * q + d2) * q + d3) * q + d4) * q + 1);
  }

  void calculateIntervalZaupanja() {
    int? x = int.tryParse(uspehiController.text);
    int? n = int.tryParse(poskusiController.text);

    if (x == null || n == null || n <= 0 || x < 0 || x > n) {
      setState(() => result = 'Invalid input');
      return;
    }

    double pHat = x / n;
    double confidence = selectedPercentile / 100;
    double alpha = 1 - confidence;
    double z = inverseNormal(1 - alpha / 2);
    double se = sqrt(pHat * (1 - pHat) / n);

    double lower = pHat - z * se;
    double upper = pHat + z * se;

    // Clamp interval to [0, 1]
    lower = lower.clamp(0.0, 1.0);
    upper = upper.clamp(0.0, 1.0);

    String postopek =
        'Interval zaupanja za delež\n\n'
        'Podatki:\n'
        'x = $x\n'
        'n = $n\n\n'
        'Ocenjeni delež:\n'
        'p̂ = x / n = $x / $n = ${pHat.toStringAsFixed(4)}\n\n'
        'Nivo zaupanja:\n'
        '${selectedPercentile}% → z = ${z.toStringAsFixed(4)}\n\n'
        'Standardna napaka:\n'
        'SE = √(p̂(1 − p̂) / n)\n'
        'SE = ${se.toStringAsFixed(4)}\n\n'
        'Interval zaupanja:\n'
        '[p̂ − z·SE, p̂ + z·SE]\n'
        '[${lower.toStringAsFixed(4)}, ${upper.toStringAsFixed(4)}]\n\n';

    String rezultat =
        'REZULTAT:\n'
        'Z ${selectedPercentile}% zaupanjem velja:\n'
        '${lower.toStringAsFixed(4)} ≤ p ≤ ${upper.toStringAsFixed(4)}';

    setState(() {
      result = postopek + rezultat;
    });
  }





  /* DOGODKI */

  String eventName(int index) {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (index < letters.length) return letters[index];
    return '${letters[index % letters.length]}${index ~/ letters.length}';
  }
  List<List<int>> generateSubsets(int n) {
    List<List<int>> subsets = [];
    for (int mask = 1; mask < (1 << n); mask++) {
      List<int> subset = [];
      for (int i = 0; i < n; i++) {
        if (mask & (1 << i) != 0) subset.add(i);
      }
      if (subset.length >= 2) subsets.add(subset);
    }
    return subsets;
  }
  void calculateDogodki() {
    List<double> probs = [];
    String postopek = '';

    for (int i = 0; i < eventControllers.length; i++) {
      double? p = double.tryParse(eventControllers[i].text);
      if (p == null || p < 0 || p > 1) {
        setState(() => result = 'Invalid probabilities');
        return;
      }
      probs.add(p);
    }

    double value = 0;

    switch (selectedDogodek) {

    // =====================
    // VSOTA DOGODKOV
    // =====================
      case Dogodki.vsota:
        final n = probs.length;
        final events = List.generate(n, (i) => eventName(i));
        final subsets = generateSubsets(n);

        postopek += 'Formula:\n';
        postopek +=
        'P(${events.join(' + ')}) =\n';

        postopek += events.map((e) => 'P($e)').join(' + ') + '\n';

        for (var subset in subsets) {
          String key = subset.map((i) => eventName(i)).join();
          if (subset.length.isEven) {
            postopek += ' − P($key)\n';
          } else {
            postopek += ' + P($key)\n';
          }
        }

        postopek += '\n';

        // --- Formula s številkami
        postopek += 'Vstavimo vrednosti:\n';
        postopek +=
        'P(${events.join(' + ')}) =\n';

        postopek += probs.map((p) => p.toString()).join(' + ') + '\n';

        value = probs.reduce((a, b) => a + b);

        for (var subset in subsets) {
          String key = subset.map((i) => eventName(i)).join();
          double? p = double.tryParse(intersectionControllers[key]?.text ?? '');

          if (p == null || p < 0 || p > 1) {
            setState(() => result = 'Invalid P($key)');
            return;
          }

          if (subset.length.isEven) {
            postopek += ' − $p\n';
            value -= p;
          } else {
            postopek += ' + $p\n';
            value += p;
          }
        }

        break;

    // =====================
    // ZMNOŽEK
    // =====================
      case Dogodki.zmnozek:
        value = probs.reduce((a, b) => a * b);

        postopek += 'Formula:\n';
        postopek +=
        'P(${List.generate(probs.length, (i) => eventName(i)).join(' ∩ ')})\n';
        postopek += '\nVstavimo vrednosti:\n';
        postopek += probs.join(' · ') + '\n';

        break;

    // =====================
    // POGOJNA
    // =====================
      case Dogodki.pogojna:
        double? pAB =
        double.tryParse(intersectionControllers['AB']?.text ?? '');
        double pB = probs[1];

        if (pAB == null || pB == 0) {
          setState(() => result = 'Invalid conditional probability');
          return;
        }

        value = pAB / pB;

        postopek += 'Formula:\n';
        postopek += 'P(A | B) = P(A ∩ B) / P(B)\n\n';
        postopek += 'Vstavimo vrednosti:\n';
        postopek += '$pAB / $pB\n';

        break;
    }

    postopek +=
    '\nREZULTAT:\n'
        '${value.toStringAsFixed(4)}';

    setState(() {
      result = postopek;
    });
  }

  void onDogodekChange(Dogodki d) {
    setState(() {
      selectedDogodek = d;
      eventControllers = [
        TextEditingController(),
        TextEditingController(),
      ];
      intersectionControllers.clear();
      result = '';
    });
  }

  /* UI */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: Column(
          children: [
            /* MODE SWITCH */
            DropdownButton<Mode>(
              value: mode,
              onChanged: (value) => setState(() => mode = value!),
              items: const [
                DropdownMenuItem(
                  value: Mode.kombinatorika,
                  child: Text('Kombinatorika'),
                ),
                DropdownMenuItem(
                  value: Mode.dogodki,
                  child: Text('Dogodki (verjetnost)'),
                ),
                DropdownMenuItem(
                  value: Mode.osVrjetnost,
                  child: Text('Vrjetnost (osnovna)'),
                ),
                DropdownMenuItem(
                  value: Mode.intervalZaupanja,
                  child: Text('Interval zaupanja'),
                ),
                DropdownMenuItem(
                  value: Mode.opisnaStatistika,
                  child: Text('Opisna statistika'),
                ),
                DropdownMenuItem(
                  value: Mode.centralniLimitniIzrek,
                  child: Text('Centralni limitni izrek'),
                ),
                DropdownMenuItem(
                  value: Mode.zgodovina,
                  child: Text('Zgodovina računanja'),
                ),
                DropdownMenuItem(
                  value: Mode.porazdelitve,
                  child: Text('Porazdelitve'),
                ),

              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  showAdvancedUI = !showAdvancedUI;
                });
              },
              icon: Icon(showAdvancedUI ? Icons.expand_less : Icons.expand_more),
              label: Text(showAdvancedUI ? 'Skrij nastavitve' : 'Prikaži nastavitve'),
            ),
          if (showAdvancedUI) ...[
            //int z
            const SizedBox(height: 10),
            if (mode == Mode.intervalZaupanja) ...[
              DropdownButton<int>(
                value: selectedPercentile,
                onChanged: (value) => setState(() => selectedPercentile = value!),
                items: List.generate(99, (i) {
                  int p = i + 1;
                  return DropdownMenuItem(
                    value: p,
                    child: Text('$p % interval zaupanja'),
                  );
                }),
              ),

              TextField(
                controller: uspehiController,
                decoration: const InputDecoration(labelText: 'Število uspehov (x)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: poskusiController,
                decoration: const InputDecoration(labelText: 'Število poskusov (n)'),
                keyboardType: TextInputType.number,
              ),
            ],
            // os vrjetnost
            if (mode == Mode.osVrjetnost) ...[
              DropdownButton<OsVrjetnost>(
                value: selectedOsVrjetnost,
                onChanged: (value) => setState(() => selectedOsVrjetnost = value!),
                items: const [
                  DropdownMenuItem(
                    value: OsVrjetnost.navadna,
                    child: Text('Navadna verjetnost'),
                  ),
                  DropdownMenuItem(
                    value: OsVrjetnost.geometrijska,
                    child: Text('Geometrijska verjetnost'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (selectedOsVrjetnost == OsVrjetnost.navadna) ...[
                TextField(
                  controller: ugodniController,
                  decoration: const InputDecoration(labelText: 'Število ugodnih izidov'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: vsiController,
                  decoration: const InputDecoration(labelText: 'Število vseh izidov'),
                  keyboardType: TextInputType.number,
                ),
              ],
              if (selectedOsVrjetnost == OsVrjetnost.geometrijska) ...[
                TextField(
                  controller: dolzinaUgodniController,
                  decoration: const InputDecoration(labelText: 'Dolžina ugodnega dela'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: dolzinaCelotaController,
                  decoration: const InputDecoration(labelText: 'Dolžina celote'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            // opisna stat
            if (mode == Mode.opisnaStatistika) ...[
              const Text(
                'Način vnosa podatkov',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              RadioListTile<OpisnaVnos>(
                title: const Text('Ročni vnos'),
                value: OpisnaVnos.rocni,
                groupValue: selectedOpisnaVnos,
                onChanged: (v) => setState(() => selectedOpisnaVnos = v!),
              ),

              RadioListTile<OpisnaVnos>(
                title: const Text('Naloži TXT datoteko'),
                value: OpisnaVnos.datoteka,
                groupValue: selectedOpisnaVnos,
                onChanged: (v) => setState(() => selectedOpisnaVnos = v!),
              ),

              if (selectedOpisnaVnos == OpisnaVnos.rocni)
                TextField(
                  controller: dataController,
                  decoration: const InputDecoration(
                    labelText: 'Podatki (ločeni z vejico)',
                    hintText: 'npr. 1, 2, 2, 3, 4',
                  ),
                ),

              if (selectedOpisnaVnos == OpisnaVnos.datoteka) ...[
                ElevatedButton(
                  onPressed: loadTxtFile,
                  child: const Text('Izberi TXT datoteko'),
                ),
                if (selectedFile != null)
                  Text(
                    'Naloženo: ${selectedFile!.path.split(Platform.pathSeparator).last}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ],


            // cli
            if (mode == Mode.centralniLimitniIzrek) ...[
              TextField(
                controller: muController,
                decoration: const InputDecoration(labelText: 'μ (pričakovana vrednost)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sigmaController,
                decoration: const InputDecoration(labelText: 'σ (standardni odklon)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: nCltController,
                decoration: const InputDecoration(labelText: 'n (velikost vzorca)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: xController,
                decoration: const InputDecoration(labelText: 'x (vrednost povprečja)'),
                keyboardType: TextInputType.number,
              ),
            ],

            /* KOMBINATORIKA UI */
            if (mode == Mode.kombinatorika) ...[
              TextField(
                controller: nController,
                decoration: const InputDecoration(labelText: 'n'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: kController,
                decoration: const InputDecoration(labelText: 'k (če je potrebno)'),
                keyboardType: TextInputType.number,
              ),
              DropdownButton<Kombinatorika>(
                value: selectedKomb,
                onChanged: (value) =>
                    setState(() => selectedKomb = value!),
                items: const [
                  DropdownMenuItem(
                    value: Kombinatorika.permutacije,
                    child: Text('Permutacije'),
                  ),
                  DropdownMenuItem(
                    value: Kombinatorika.variacije,
                    child: Text('Variacije'),
                  ),
                  DropdownMenuItem(
                    value: Kombinatorika.kombinacije,
                    child: Text('Kombinacije'),
                  ),
                ],
              ),
            ],

            /* DOGODKI UI */
            if (mode == Mode.dogodki) ...[
              ...List.generate(eventControllers.length, (i) {
                return TextField(
                  controller: eventControllers[i],
                  decoration: InputDecoration(labelText: 'P(${eventName(i)})'),
                  keyboardType: TextInputType.number,
                );
              }),

              if (selectedDogodek != Dogodki.pogojna)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      eventControllers.add(TextEditingController());
                    });
                  },
                  child: const Text('Dodaj dogodek'),
                ),
              
              if (selectedDogodek == Dogodki.vsota ||
                  selectedDogodek == Dogodki.zmnozek)
                SizedBox(
                  height: 250, // ← prilagodi po potrebi
                  child: SingleChildScrollView(
                    child: Column(
                      children: generateSubsets(eventControllers.length).map((subset) {
                        String key = subset.map((i) => eventName(i)).join();

                        intersectionControllers.putIfAbsent(
                          key,
                              () => TextEditingController(),
                        );

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: TextField(
                            controller: intersectionControllers[key],
                            decoration: InputDecoration(labelText: 'P($key)'),
                            keyboardType: TextInputType.number,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              // dropdown
              DropdownButton<Dogodki>(
                value: selectedDogodek,
                onChanged: (v) => onDogodekChange(v!),
                items: const [
                  DropdownMenuItem(
                    value: Dogodki.vsota,
                    child: Text('Vsota dogodkov'),
                  ),
                  DropdownMenuItem(
                    value: Dogodki.zmnozek,
                    child: Text('Zmnožek dogodkov'),
                  ),
                  DropdownMenuItem(
                    value: Dogodki.pogojna,
                    child: Text('Pogojna verjetnost'),
                  ),
                ],
              ),
            ],


            /* ZGODOVINA UI */
            if (mode == Mode.zgodovina) ...[
              Expanded(
                child: history.isEmpty
                    ? const Center(
                  child: Text(
                    'Ni shranjenih izračunov',
                    style: TextStyle(fontSize: 18),
                  ),
                )
                    : ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(entry.result,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                            '${entry.mode.name}, ${entry.time.toLocal().toString().split(".")[0]}'),
                        onTap: () => restoreFromHistory(entry),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() => history.clear());
                  final prefs = await SharedPreferences.getInstance();
                  prefs.remove('history'); // lokalno briše
                },
                icon: const Icon(Icons.delete),
                label: const Text('Počisti zgodovino'),
              ),
            ],

            // porazdelitve
            if (mode == Mode.porazdelitve) ...[
              const Text(
                'Tip porazdelitve',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              DropdownButton<TipPorazdelitve>(
                value: selectedTip,
                onChanged: (v) => setState(() => selectedTip = v!),
                items: const [
                  DropdownMenuItem(
                    value: TipPorazdelitve.diskretna,
                    child: Text('Diskretna'),
                  ),
                  DropdownMenuItem(
                    value: TipPorazdelitve.zvezna,
                    child: Text('Zvezna'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              /* ================= DISKRETNE ================= */
              if (selectedTip == TipPorazdelitve.diskretna) ...[
                DropdownButton<DiskretnaPorazdelitev>(
                  value: selectedDiskretna,
                  onChanged: (v) => setState(() => selectedDiskretna = v!),
                  items: const [
                    DropdownMenuItem(
                      value: DiskretnaPorazdelitev.bernoulli,
                      child: Text('Bernoullijeva'),
                    ),
                    DropdownMenuItem(
                      value: DiskretnaPorazdelitev.binomska,
                      child: Text('Binomska'),
                    ),
                    DropdownMenuItem(
                      value: DiskretnaPorazdelitev.poisson,
                      child: Text('Poissonova'),
                    ),
                  ],
                ),

                if (selectedDiskretna == DiskretnaPorazdelitev.bernoulli) ...[
                  TextField(
                    controller: pController,
                    decoration: const InputDecoration(labelText: 'p'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: xDistController,
                    decoration: const InputDecoration(labelText: 'x (0 ali 1)'),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedDiskretna == DiskretnaPorazdelitev.binomska) ...[
                  TextField(
                    controller: nDistController,
                    decoration: const InputDecoration(labelText: 'n'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: kDistController,
                    decoration: const InputDecoration(labelText: 'k'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: pController,
                    decoration: const InputDecoration(labelText: 'p'),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedDiskretna == DiskretnaPorazdelitev.poisson) ...[
                  TextField(
                    controller: kDistController,
                    decoration: const InputDecoration(labelText: 'k'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: lambdaController,
                    decoration: const InputDecoration(labelText: 'λ'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],

              /* ================= ZVEZNE ================= */
              if (selectedTip == TipPorazdelitve.zvezna) ...[
                DropdownButton<ZveznaPorazdelitev>(
                  value: selectedZvezna,
                  onChanged: (v) => setState(() => selectedZvezna = v!),
                  items: const [
                    DropdownMenuItem(
                      value: ZveznaPorazdelitev.normalna,
                      child: Text('Normalna'),
                    ),
                    DropdownMenuItem(
                      value: ZveznaPorazdelitev.eksponentna,
                      child: Text('Eksponentna'),
                    ),
                    DropdownMenuItem(
                      value: ZveznaPorazdelitev.uniformna,
                      child: Text('Uniformna'),
                    ),
                  ],
                ),

                if (selectedZvezna == ZveznaPorazdelitev.normalna) ...[
                  TextField(
                    controller: xDistController,
                    decoration: const InputDecoration(labelText: 'x'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: muController,
                    decoration: const InputDecoration(labelText: 'μ'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: sigmaController,
                    decoration: const InputDecoration(labelText: 'σ'),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedZvezna == ZveznaPorazdelitev.eksponentna) ...[
                  TextField(
                    controller: xDistController,
                    decoration: const InputDecoration(labelText: 'x'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: lambdaController,
                    decoration: const InputDecoration(labelText: 'λ'),
                    keyboardType: TextInputType.number,
                  ),
                ],

                if (selectedZvezna == ZveznaPorazdelitev.uniformna) ...[
                  TextField(
                    controller: xDistController,
                    decoration: const InputDecoration(labelText: 'x'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: aController,
                    decoration: const InputDecoration(labelText: 'a'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: bController,
                    decoration: const InputDecoration(labelText: 'b'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ],
            ],
          ],
            // neslednje
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (mode == Mode.kombinatorika) {
                  calculateKombinatorika();
                } else if (mode == Mode.dogodki) {
                  calculateDogodki();
                } else if (mode == Mode.osVrjetnost) {
                  calculateOsVrjetnost();
                } else if (mode == Mode.intervalZaupanja) {
                  calculateIntervalZaupanja();
                }else if (mode == Mode.opisnaStatistika) {
                  calculateOpisnaStatistika();
                }else if (mode == Mode.centralniLimitniIzrek) {
                  calculateCLT();
                }
                else if (mode == Mode.porazdelitve) {
                  calculatePorazdelitve();
                }


              },


              child: const Text('Izračunaj'),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: SelectableText(
                  'Rezultat:\n\n$result',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
