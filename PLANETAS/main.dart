import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Planetas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: PlanetListScreen(),
    );
  }
}

class Planet {
  final int? id;
  final String name;
  final double distance;
  final double size;
  final String? nickname;

  Planet({this.id, required this.name, required this.distance, required this.size, this.nickname});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distance': distance,
      'size': size,
      'nickname': nickname,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('planets.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        distance REAL NOT NULL,
        size REAL NOT NULL,
        nickname TEXT
      )
    ''');
  }

  Future<int> insertPlanet(Planet planet) async {
    final db = await instance.database;
    return await db.insert('planets', planet.toMap());
  }

  Future<List<Planet>> getPlanets() async {
    final db = await instance.database;
    final result = await db.query('planets');
    return result.map((json) => Planet(
      id: json['id'] as int?,
      name: json['name'] as String,
      distance: json['distance'] as double,
      size: json['size'] as double,
      nickname: json['nickname'] as String?,
    )).toList();
  }

  Future<int> updatePlanet(Planet planet) async {
    final db = await instance.database;
    return await db.update(
      'planets',
      planet.toMap(),
      where: 'id = ?',
      whereArgs: [planet.id],
    );
  }

  Future<int> deletePlanet(int id) async {
    final db = await instance.database;
    return await db.delete(
      'planets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class PlanetListScreen extends StatefulWidget {
  @override
  _PlanetListScreenState createState() => _PlanetListScreenState();
}

class _PlanetListScreenState extends State<PlanetListScreen> {
  List<Planet> planets = [];

  @override
  void initState() {
    super.initState();
    _loadPlanets();
  }

  Future<void> _loadPlanets() async {
    final data = await DatabaseHelper.instance.getPlanets();
    setState(() {
      planets = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Planetas Cadastrados')),
      body: ListView.builder(
        itemCount: planets.length,
        itemBuilder: (context, index) {
          final planet = planets[index];
          return ListTile(
            title: Text(planet.name),
            subtitle: Text(planet.nickname ?? 'Sem apelido'),
            onTap: () {
             Navigator.push(
               context,  MaterialPageRoute( builder: (context) => PlanetDetailScreen(planet: planet), ),
               ).then((_) => _loadPlanets());
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPlanetScreen()),
          ).then((_) => _loadPlanets());
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddPlanetScreen extends StatefulWidget {
  final Planet? planet;

  AddPlanetScreen({this.planet});

  @override
  _AddPlanetScreenState createState() => _AddPlanetScreenState();
}

class _AddPlanetScreenState extends State<AddPlanetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _distanceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.planet != null) {
      _nameController.text = widget.planet!.name;
      _distanceController.text = widget.planet!.distance.toString();
      _sizeController.text = widget.planet!.size.toString();
      _nicknameController.text = widget.planet!.nickname ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planet == null ? 'Adicionar Planeta' : 'Editar Planeta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome do Planeta'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do planeta';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _distanceController,
                decoration: InputDecoration(labelText: 'Distância do Sol (milhões de km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a distância do planeta';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Distância inválida';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _sizeController,
                decoration: InputDecoration(labelText: 'Tamanho do Planeta (km)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o tamanho do planeta';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Tamanho inválido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(labelText: 'Apelido (opcional)'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final planet = Planet(
                      id: widget.planet?.id,
                      name: _nameController.text,
                      distance: double.parse(_distanceController.text),
                      size: double.parse(_sizeController.text),
                      nickname: _nicknameController.text.isNotEmpty ? _nicknameController.text : null,
                    );

                    if (widget.planet == null) {
                      DatabaseHelper.instance.insertPlanet(planet).then((_) {
                        Navigator.pop(context);
                      });
                    } else {
                      DatabaseHelper.instance.updatePlanet(planet).then((_) {
                        Navigator.pop(context);
                      });
                    }
                  }
                },
                child: Text(widget.planet == null ? 'Salvar Planeta' : 'Atualizar Planeta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanetDetailScreen extends StatelessWidget {
  final Planet planet;

  PlanetDetailScreen({required this.planet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detalhes do Planeta')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nome: ${planet.name}', style: TextStyle(fontSize: 18)),
            Text('Distância: ${planet.distance} milhões de km', style: TextStyle(fontSize: 18)),
            Text('Tamanho: ${planet.size} km', style: TextStyle(fontSize: 18)),
            Text('Apelido: ${planet.nickname ?? "Sem apelido"}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddPlanetScreen(planet: planet),
                      ),
                    );
                  },
                  child: Text('Editar'),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Excluir Planeta'),
                          content: Text('Tem certeza que deseja excluir ${planet.name}?'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () {
                                DatabaseHelper.instance.deletePlanet(planet.id!).then((_) {
                                  Navigator.pop(context); // Fecha o diálogo
                                  Navigator.pop(context); // Volta para a lista
                                });
                              },
                              child: Text('Excluir'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Excluir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}