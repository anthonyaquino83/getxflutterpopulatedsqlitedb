import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:getxflutterpopulatedsqlitedb/app/data/model/note_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class NotesService extends GetxService {
  //o banco de dados declarado como late sera inicializado na primeira leitura
  late Database db;

  Future<NotesService> init() async {
    db = await _useDatabase('notes.db');
    return this;
  }

  Future<Database> _useDatabase(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    // await deleteDatabase(path);

    // verificar se a base dados ja existe no diretorio de instalacao do app
    var exists = await databaseExists(path);

    // Se a base de dados nao existir, fazer uma nova copia
    if (!exists) {
      print("Criar nova copia do diretorio do app");

      // Verificar se o diretorio existe
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Ler o arquivo da base de dados na pasta de recursos (assets)
      // onde o app esta instalado no dispositivo
      ByteData data = await rootBundle.load(join("assets", "notes.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Escrever conteudo da base de dados
      await File(path).writeAsBytes(bytes, flush: true);
    } else {
      print("Abrir uma base de dados existente");
    }
    //abrir base de dados
    return await openDatabase(path, readOnly: false);
  }

  // recuperar todas as notas
  Future<List<Note>> getAll() async {
    final result = await db.rawQuery('SELECT * FROM notes ORDER BY id');
    print(result);
    return result.map((json) => Note.fromJson(json)).toList();
  }

  //criar nova nota
  Future<Note> save(Note note) async {
    final id = await db.rawInsert(
        'INSERT INTO notes (title, content) VALUES (?,?)',
        [note.title, note.content]);

    print(id);
    return note.copy(id: id);
  }

  //atualizar nota
  Future<Note> update(Note note) async {
    final id = await db.rawUpdate(
        'UPDATE notes SET title = ?, content = ? WHERE id = ?',
        [note.title, note.content, note.id]);

    print(id);
    return note.copy(id: id);
  }

  //excluir nota
  Future<int> delete(int noteId) async {
    final id = await db.rawDelete('DELETE FROM notes WHERE id = ?', [noteId]);

    print(id);
    return id;
  }

  //fechar conexao com o banco de dados, funcao nao usada nesse app
  Future close() async {
    db.close();
  }
}
