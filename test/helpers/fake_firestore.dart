// cloud_firestore marks these classes @sealed, but a fake has to implement them.
// ignore_for_file: subtype_of_sealed_class
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// A tiny in-memory Firestore so repositories can be tested without Firebase.
/// It only supports what the repositories use: doc get / set / update /
/// delete and transactions. Anything else throws, so a test fails loudly.
class FakeFirestore extends Fake implements FirebaseFirestore {
  /// collection name -> document id -> data.
  final Map<String, Map<String, Map<String, dynamic>>> store = {};

  /// When set, every read or write throws this error (to test error handling).
  FirebaseException? failWith;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FakeCollection(this, path);

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) => transactionHandler(_FakeTransaction());

  Map<String, dynamic>? read(String collection, String id) =>
      store[collection]?[id];

  void _check() {
    if (failWith != null) throw failWith!;
  }
}

class _FakeCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FakeCollection(this._db, this._name);

  final FakeFirestore _db;
  final String _name;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeDocRef(_db, _name, path!);
}

class _FakeDocRef extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FakeDocRef(this._db, this._collection, this.id);

  final FakeFirestore _db;
  final String _collection;

  @override
  final String id;

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    _db._check();
    return _FakeSnapshot(id, _db.read(_collection, id));
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    _db._check();
    _db.store.putIfAbsent(_collection, () => {})[id] = Map.of(data);
  }

  @override
  Future<void> update(Map<Object, Object?> data) async {
    _db._check();
    final current = _db.read(_collection, id);
    if (current == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'not-found',
        message: 'No document to update',
      );
    }
    current.addAll(data.cast<String, dynamic>());
  }

  @override
  Future<void> delete() async {
    _db._check();
    _db.store[_collection]?.remove(id);
  }
}

class _FakeSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot(this.id, this._data);

  @override
  final String id;
  final Map<String, dynamic>? _data;

  @override
  bool get exists => _data != null;

  @override
  Map<String, dynamic>? data() => _data;
}

class _FakeTransaction extends Fake implements Transaction {
  @override
  Future<DocumentSnapshot<T>> get<T extends Object?>(
    DocumentReference<T> documentReference,
  ) => documentReference.get();

  @override
  Transaction set<T>(
    DocumentReference<T> documentReference,
    T data, [
    SetOptions? options,
  ]) {
    documentReference.set(data);
    return this;
  }
}
