/*
 * Copyright (C) 2020. by perol_notsf, All rights reserved
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but WITHOUT ANY
 *  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 *  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License along with
 *  this program. If not, see <http://www.gnu.org/licenses/>.
 */
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class TaskPersist {
  int id;
  String userName;
  String fileName;
  String title;
  String url;
  int userId;
  int illustId;
  int status;

  TaskPersist(
      {this.userName,
      this.title,
      this.url,
      this.userId,
      this.illustId,
      this.fileName,
      this.status});

  TaskPersist.fromJson(Map<String, dynamic> json) {
    id = json[columnId];
    userName = json[columnUserName];
    title = json[columnTitle];
    url = json[columnUrl];
    userId = json[columnUserId];
    illustId = json[columnIllustId];
    status = json[columnStatus];
    fileName = json[columnFileName];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data[columnId] = this.id;
    data[columnUrl] = this.url;
    data[columnTitle] = this.title;
    data[columnUserName] = this.userName;
    data[columnIllustId] = this.illustId;
    data[columnUserId] = this.userId;
    data[columnStatus] = this.status;
    data[columnFileName] = this.fileName;
    return data;
  }
}

final String tableAccount = 'task';
final String columnId = 'id';
final String columnUrl = 'url';
final String columnTitle = 'title';
final String columnUserName = 'user_name';
final String columnIllustId = 'illust_id';
final String columnUserId = 'user_id';
final String columnStatus = 'status';
final String columnFileName = 'file_name';

class TaskPersistProvider {
  Database db;

  Future open() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'task.db');
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute('''
create table $tableAccount ( 
  $columnId integer primary key autoincrement, 
  $columnTitle text not null,
  $columnUserName text not null,
  $columnUrl text not null,
  $columnIllustId integer not null,
  $columnUserId integer not null,
  $columnStatus integer not null,
  $columnFileName text not null
  )
''');
    });
  }

  Future<TaskPersist> insert(TaskPersist todo) async {
    todo.id = await db.insert(tableAccount, todo.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return todo;
  }

  Future<TaskPersist> getAccount(String id) async {
    List<Map> maps = await db.query(tableAccount,
        columns: [
          columnId,
          columnUserId,
          columnIllustId,
          columnFileName,
          columnTitle,
          columnUserName,
          columnUrl,
          columnStatus
        ],
        where: '$columnUrl = ?',
        whereArgs: [id]);
    if (maps.length > 0) {
      return TaskPersist.fromJson(maps.first);
    }
    return null;
  }

  Future<int> remove(int id) async {
    final result =
        await db.delete(tableAccount, where: '$columnId = ?', whereArgs: [id]);

    return result;
  }

  Future<int> deleteAll() async {
    final result = await db.delete(tableAccount);

    return result;
  }

  Future<int> update(TaskPersist todo) async {
    return await db.update(tableAccount, todo.toJson(),
        where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future<List<TaskPersist>> getAllAccount() async {
    List result = new List<TaskPersist>();
    List<Map> maps = await db.query(tableAccount, columns: [
      columnId,
      columnUserId,
      columnIllustId,
      columnTitle,
      columnUserName,
      columnUrl,
      columnFileName,
      columnStatus
    ]);

    if (maps.length > 0) {
      maps.forEach((f) {
        result.add(TaskPersist.fromJson(f));
      });
    }
    return result;
  }
}
