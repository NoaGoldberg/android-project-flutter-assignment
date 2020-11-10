import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


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
    return ChangeNotifierProvider<UserRepository>(
        create: (_) => UserRepository.instance(),
    child: MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.red,
      ),
      home: RandomWords(),
    )
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

  @override
  Widget build(BuildContext context) {
    return  Consumer<UserRepository>(
          builder: (context, UserRepository user, _) {
            return Scaffold(
              appBar: AppBar(
                title: Text('Startup Name Generator'),
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
          );
    // });
  }

  void _login() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Consumer<UserRepository>(
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
          );
        }// ...to here.
      ),
    );
  }

  void _pushSaved() {
    Navigator.of(context).push(
        MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Consumer<UserRepository>(
                  builder: (context, user, _) {
                    return StreamBuilder<DocumentSnapshot>(
                        stream: user.status != Status.Authenticated
                            ? null
                            : FirebaseFirestore.instance.collection("Users")
                            .doc(user.user.uid)
                            .snapshots(),
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
                          if (user.status == Status.Authenticated) {
                            user.addAll(snapshot.data.data()["likes"]
                                .map<WordPair>((e) =>
                                WordPair(e.split(",")[0], e.split(",")[1]))
                                .toList());
                          }
                          final tiles = user.saved.map(
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
                                            user.removePair(pair);
                                          }
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
                            body: ListView(children: divided),
                          );
                        });
                  }
              );
            }

    )
    );
  }

  Widget _buildSuggestions() {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }

          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index]);
        }
    );
  }

  Widget _buildRow(WordPair pair) {
    return Consumer<UserRepository>(
        builder: (context, user, _) {
          final alreadySaved = user.saved.contains(pair);
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
              if (alreadySaved) {
                user.removePair(pair);
              } else {
                user.addPair(pair);
              }
            },
          );
        }
    );
  }
}
