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
      _saved.forEach((element) {addPair(element); });
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

  // Future<void> updateSaved() async {
  //   try {
  //     await FirebaseFirestore.instance.collection("Users").doc(_user.uid).get().then((snapshot) {
  //       _saved.addAll(snapshot.data()["likes"]
  //                     .map<WordPair>((e) =>
  //                     WordPair(e.split(",")[0], e.split(",")[1]))
  //                     .toList());
  //     });
  //   } catch (e) {
  //     // Do nothing, not connected or whatever
  //   }
  // }
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
