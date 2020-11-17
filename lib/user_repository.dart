import 'dart:convert';
import 'dart:io';

import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;
  Set<WordPair> _saved = Set<WordPair>();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String imageUrl;

  Future<String> getImageUrl(String name) {
    return _storage.ref('images').child(name).getDownloadURL();
  }

  Future<String> uploadNewImage(File file, String name) {
    return _storage
        .ref('images')
        .child(name)
        .putFile(file)
        .then((snapshot) => snapshot.ref.getDownloadURL());
  }

  UserRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_authStateChanges);
  }

  Status get status => _status;
  User get user => _user;
  Set<WordPair> get saved => _saved;

  Future<bool> signIn(String email, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      DocumentSnapshot ds = await FirebaseFirestore.instance.collection("Users").doc(
          _user.uid).get();
      if (!ds.exists) {
        FirebaseFirestore.instance.collection("Users").doc(_user.uid).set(
            {'likes': new List<String>()});
      }
      try {
        await getImageUrl(_user.uid + ".png").then((value) => imageUrl = value);
      } catch(e) {
        await getImageUrl("default.png").then((value) => imageUrl = value);
      }
      _saved.forEach((element) {addPair(element); });
      notifyListeners();
      return true;
    } catch (e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    try {
      _auth.createUserWithEmailAndPassword(email: email, password: password);
      return await signIn(email, password);
    } catch(e) {
      _status = Status.Unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> removePair(WordPair pair) async {
    _saved.remove(pair);
    if (_status == Status.Authenticated) {
      FirebaseFirestore.instance.collection("Users")
          .doc(_user.uid)
          .update(
          {"likes": FieldValue.arrayRemove([pair.join(",")])});
    }
    notifyListeners();
  }
  Future<void> addPair(WordPair pair) async {
      _saved.add(pair);
    if (_status == Status.Authenticated) {
      FirebaseFirestore.instance.collection("Users").doc(
          _user.uid).update(
          {"likes": FieldValue.arrayUnion([pair.join(",")])});
    }
    notifyListeners();
  }

  Future addAll(List<WordPair> toAdd) async {
    if (_status == Status.Authenticated) {
      _saved.clear();
      _saved.addAll(toAdd);
    }
    notifyListeners();
  }

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
    _saved.clear();
    imageUrl = null;
    notifyListeners();
    return Future.delayed(Duration.zero);
  }

  Future<void> _authStateChanges(User firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }
}
