import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
            body: Center(
                child: Text(snapshot.error.toString(),
                    textDirection: TextDirection.ltr)));
      }
      if (snapshot.connectionState == ConnectionState.done) {
        return MyApp();
      }
      return Center(child: CircularProgressIndicator());
        },
    );
  }
}

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Text("Loading..."),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: RandomWords(),
    );
  }
}

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final List<WordPair> _suggestions = <WordPair>[];
  final TextStyle _biggerFont = const TextStyle(fontSize: 18);
  final _saved = Set<WordPair>();

  // Future<List<WordPair>> getWordPairs(String groupId) async {
  //   var document =
  //   FirebaseFirestore.instance.collection("Users").doc(groupId).snapshots();
  //   return await document((doc) {
  //     // return [WordPair(doc.data()["likes"][0], "haha")];
  //     return doc.data()["likes"].map<WordPair>((e) => WordPair(e.split(",")[0], e.split(",")[1])).toList();
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    // return StreamBuilder<QueryDocumentSnapshot>(
    //     stream: _getData(user),
    //     builder: (BuildContext context,
    //         AsyncSnapshot<QueryDocumentSnapshot> snapshot) {
    return ChangeNotifierProvider<UserRepository>(
      create: (_) => UserRepository.instance(),
      child: Consumer<UserRepository>(
          builder: (context, UserRepository user, _) {
            return Scaffold(
              appBar: AppBar(
                title: /*StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection("Users").doc(user.user.uid).snapshots(),
              builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {

              if (snapshot.hasError) {
              return Text("${snapshot.error.toString()}", style:  TextStyle(fontSize: 6),);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text("loading");
              }
              Map<String, dynamic> data = snapshot.data.data();
              return Text("Test: ${data['likes'][1]}");



              },
              ),*/ Text('Startup Name Generator'),
                actions: [
                  IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
                  IconButton(icon: user.status != Status.Authenticated ? Icon(
                      Icons.login) : Icon(Icons.logout),
                      onPressed: user.status != Status.Authenticated
                          ? _login
                          : () =>
                          Provider.of<UserRepository>(context, listen: false)
                              .signOut()),
                ],
              ),
              body: _buildSuggestions(),
            );
          }
      ),
    );
    // });
  }

  void _login() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ChangeNotifierProvider<UserRepository>(
            create: (_) => UserRepository.instance(),
            child: Consumer<UserRepository>(
              builder: (context, UserRepository user, _) {
                switch (user.status) {
                  case Status.Uninitialized:
                    return Splash();
                  case Status.Unauthenticated:
                  case Status.Authenticating:
                    return LoginPage();
                  case Status.Authenticated:
                    Navigator.of(context).pop();
                }
                return RandomWords();
              },
            ),
          );
        }, // ...to here.
      ),
    );
  }

  Future<void> _pushSaved() async {
    // UserRepository loginState = Provider.of(context, listen:false);
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return ChangeNotifierProvider<UserRepository>(
                  create: (_) => UserRepository.instance(),
                  child: Consumer<UserRepository>(
                      builder: (context, UserRepository user, _) {
                        return StreamBuilder<DocumentSnapshot>(
                            stream: user.status != Status.Authenticated
                                ? null
                                : FirebaseFirestore.instance.collection("Users")
                                .doc(user.user.uid)
                                .snapshots(),
                            //getWordPairs(user.user.uid), // TODO: handle not auth!!!!
                            builder: (BuildContext context,
                                AsyncSnapshot<DocumentSnapshot> snapshot) {
                              if (snapshot.hasError) {
                                return Text("${snapshot.error.toString()}",
                                  style: TextStyle(fontSize: 16),);
                              }
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              final _favorites = user.status ==
                                  Status.Authenticated ?
                              snapshot.data.data()["likes"]
                                  .map<WordPair>((e) =>
                                  WordPair(e.split(",")[0], e.split(",")[1]))
                                  .toList() //snapshot.data; //[WordPair("blaaa", "blu")]
                                  : _saved;
                              final tiles = _favorites.map<Widget>(
                                    (WordPair pair) {
                                  return ListTile(
                                    title: Text(
                                      pair.asPascalCase,
                                      style: _biggerFont,
                                    ),
                                    trailing: Builder(
                                      builder: (context) =>
                                          IconButton(
                                              icon: Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  if (user.status ==
                                                      Status.Authenticated) {
                                                    // remove from DB
                                                    FirebaseFirestore.instance
                                                        .collection("Users")
                                                        .doc(user.user.uid)
                                                        .update({
                                                      "likes": FieldValue
                                                          .arrayRemove(
                                                          [pair.join(",")])
                                                    });
                                                  } else {
                                                    // TODO: figure how to update UI!
                                                  }
                                                  _saved.remove(pair);
                                                });
                                              }
                                            //    final snackBar = SnackBar(
                                            //      content: Text(
                                            //          "Deletion is not implemented yet"),
                                            //      action: SnackBarAction(
                                            //        label: 'OK',
                                            //        textColor: Colors.red,
                                            //        onPressed: () {},
                                            //      ),
                                            //    );
                                            //    Scaffold.of(context).showSnackBar(
                                            //        snackBar);
                                            // }


                                          ),
                                    ),
                                  );
                                },
                              ).toList();

                              final divided = ListTile.divideTiles(
                                context: context,
                                tiles: tiles,
                              ).toList();

                              return Scaffold(
                                appBar: AppBar(
                                  title: Text('Saved Suggestions'),
                                ),
                                body: ListView.builder(
                                  itemBuilder: (context, item) {
                                    return divided[item];
                                  },
                                  itemCount: divided.length,
                                ),
                                // body: ListView(children: divided),
                              );
                            });
                      }
                  )
              );
            }
        )
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        // The itemBuilder callback is called once per suggested
        // word pairing, and places each suggestion into a ListTile
        // row. For even rows, the function adds a ListTile row for
        // the word pairing. For odd rows, the function adds a
        // Divider widget to visually separate the entries. Note that
        // the divider may be difficult to see on smaller devices.
        itemBuilder: (BuildContext _context, int i) {
          // Add a one-pixel-high divider widget before each row
          // in the ListView.
          if (i.isOdd) {
            return Divider();
          }

          // The syntax "i ~/ 2" divides i by 2 and returns an
          // integer result.
          // For example: 1, 2, 3, 4, 5 becomes 0, 1, 1, 2, 2.
          // This calculates the actual number of word pairings
          // in the ListView,minus the divider widgets.
          final int index = i ~/ 2;
          // If you've reached the end of the available word
          // pairings...
          if (index >= _suggestions.length) {
            // ...then generate 10 more and add them to the
            // suggestions list.
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  Widget _buildRow(WordPair pair) {
    final alreadySaved = _saved.contains(pair);
    return Consumer<UserRepository>(
        builder: (context, UserRepository user, _) {
          return ListTile(
            title: Text(
              pair.asPascalCase,
              style: _biggerFont,
            ),
            trailing: Icon(
              alreadySaved ? Icons.favorite : Icons.favorite_border,
              color: alreadySaved ? Colors.red : null,
            ),
            onTap: () {
              setState(() {
                if (alreadySaved) {
                  if (user.status == Status.Authenticated) {
                    FirebaseFirestore.instance.collection("Users")
                        .doc(user.user.uid)
                        .update(
                        {"likes": FieldValue.arrayRemove([pair.join(",")])});
                  }
                  _saved.remove(pair);
                } else {
                  _saved.add(pair);
                  if (user.status == Status.Authenticated) {
                    FirebaseFirestore.instance.collection("Users").doc(
                        user.user.uid).update(
                        {"likes": FieldValue.arrayUnion([pair.join(",")])});
                  }
                }
              });
            },
          );
        }
    );
  }
}
