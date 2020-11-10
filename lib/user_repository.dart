import 'dart:convert';

import 'package:english_words/english_words.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class UserRepository with ChangeNotifier {
  FirebaseAuth _auth;
  User _user;
  Status _status = Status.Uninitialized;
  Set<WordPair> _saved = Set<WordPair>();

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
      return true;
    } catch (e) {
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
  bool alreadySaved (WordPair pair) {
    return _saved.contains(pair);
  }

  Future<IconData> getIcon(pair) async{
  return this.alreadySaved(pair) ? Icons.favorite : Icons.favorite_border;
}

  Future signOut() async {
    _auth.signOut();
    _status = Status.Unauthenticated;
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
