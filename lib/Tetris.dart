import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'dart:math';
import "Block.dart";

class Tetris extends StatefulWidget {
  @override
  _TetrisState createState() => _TetrisState();
}

class _TetrisState extends State<Tetris> {
  static const int MAX_WIDTH = 12;
  static const int MAX_HEIGHT = 24;
  static const int HIDDEN_HEIGHT = 4;
  final _rnd = Random();

  late Timer _timer;
  List<List<int>> _cell = List.generate(MAX_HEIGHT, (_) => List.generate(MAX_WIDTH, (_) => 0));
  Block _block = Block();
  int _score = 0;
  bool _rotateFlag = false;

  _TetrisState() {
    init();
  }

  init() {
    for (int i = 0; i < MAX_HEIGHT; i++) {
      for (int j = 0; j < MAX_WIDTH; j++) {
        if (i == MAX_HEIGHT - 1 || j == 0 || j == MAX_WIDTH - 1) {
          _cell[i][j] = 1;
        } else {
          _cell[i][j] = 0;
        }
      }
    }

    _score = 0;

    createBlock();

    _timer = Timer.periodic(Duration(milliseconds: 50), (Timer timer) {
      update();
    });
  }

  createBlock() {
    _block = Block();
    _block.type = _rnd.nextInt(Block.Mino.length);
    _block.posx = MAX_WIDTH ~/ 2 - 1;
    _block.posy = 0;

    if (hitTest(0)) {
      gameOver();
    }
  }

  int _frameCount = 0;
  update() {
    _frameCount++;

    if (_key == 0 || _frameCount % 10 == 0) {
      onUserControl(0);
    } else if (_key != 0) {
      onUserControl(_key);
    }
  }

  fixBlock() {
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        int px = _block.posx + j;
        int py = _block.posy + i;
        if (px >= 0 && px < MAX_WIDTH && py >= 0 && py < MAX_HEIGHT) {
          if (Block.Mino[_block.type][_block.direction][i][j] != 0) {
            _cell[py][px] = 1;
          }
        }
      }
    }
  }

  lineCheck() {
    for (int i = max(_block.posy, 0); i < min(_block.posy + 4, MAX_HEIGHT - 1); i++) {
      int count = 0;
      for (int j = 0; j < MAX_WIDTH; j++) {
        if (_cell[i][j] == 0) break;
        count++;
      }
      if (count == MAX_WIDTH) {
        _cell.removeAt(i);
        _cell.insert(0, List.generate(MAX_WIDTH, (_) => 0));
        _cell[0][0] = _cell[0][MAX_WIDTH - 1] = 1;
        _score++;
      }
    }
  }

  bool hitTest(int direction) {
    int x = 0;
    int y = 0;
    int d = 0;

    if (direction == 0) {
      y = 1;
    } else if (direction == 1) {
      x = -1;
    } else if (direction == 3) {
      x = 1;
    } else if (direction == -1) {
      d = 1;
    }

    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        int px = _block.posx + j + x;
        int py = _block.posy + i + y;
        if (px >= 0 && px < MAX_WIDTH && py >= 0 && py < MAX_HEIGHT) {
          if (_cell[py][px] != 0 && Block.Mino[_block.type][(_block.direction + d) % 4][i][j] != 0) {
            return true;
          }
        }
      }
    }

    return false;
  }

  Container getCell(int index) {
    Color color;
    int x = index % MAX_WIDTH;
    int y = (index / MAX_WIDTH).floor();

    switch (_cell[y][x]) {
      case 0:
        color = Color(0xffaaaaaa);
        break;
      case 1:
        color = Color(0xff444444);
        break;
      default:
        color = Color(0xff444444);
        break;
    }

    if (x >= _block.posx && x < _block.posx + 4 && y >= _block.posy && y < _block.posy + 4) {
      if (Block.Mino[_block.type][_block.direction][y - _block.posy][x - _block.posx] != 0) {
        color = Color(0xff3333bb);
      }
    }

    return Container(
      margin: EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.rectangle,
      ),
    );
  }

  int _key = -1;
  var _focusNode = FocusNode();
  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).requestFocus(_focusNode);
    return Scaffold(
      appBar: AppBar(
        leading: Icon(Icons.videogame_asset_outlined),
        // タイトルテキスト
        title: Text('Flutter Tetris'),
        actions: <Widget>[
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.favorite),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: <Widget>[
          Expanded(
            child: RawKeyboardListener(
              autofocus: true,
              focusNode: _focusNode,
              onKey: (event) {
                if (event is RawKeyUpEvent) {
                  _key = -1;
                  _rotateFlag = false;
                } else if (event is RawKeyDownEvent) {
                  if (event.data.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    _key = 1;
                  } else if (event.data.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _key = 2;
                  } else if (event.data.logicalKey == LogicalKeyboardKey.arrowRight) {
                    _key = 3;
                  } else if (event.data.logicalKey == LogicalKeyboardKey.arrowDown) {
                    _key = 0;
                  }
                }
              },
              child: Padding(
                padding: EdgeInsets.all(30),
                child: GestureDetector(
                  child: AspectRatio(
                    aspectRatio: MAX_WIDTH / (MAX_HEIGHT - HIDDEN_HEIGHT),
                    child: GridView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: MAX_WIDTH,
                        ),
                        itemCount: MAX_WIDTH * (MAX_HEIGHT - HIDDEN_HEIGHT),
                        itemBuilder: (BuildContext context, int index) {
                          return getCell(index + MAX_WIDTH * HIDDEN_HEIGHT);
                        }),
                  ),
                ),
              ),
            ),
          ),
          createButtons()
        ],
      ),
    );
  }

  Row createButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        TextButton(
            child: Text(
              ' ← ',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              onUserControl(1);
            }),
        TextButton(
            child: Text(
              ' ↑ ',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              _rotateFlag = false;
              onUserControl(2);
            }),
        TextButton(
            child: Text(
              ' ↓ ',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              onUserControl(0);
            }),
        TextButton(
            child: Text(
              ' → ',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            onPressed: () {
              onUserControl(3);
            }),
        Text(
          (_score * 100).toString(),
          style: TextStyle(color: Colors.white, fontSize: 20),
        )
      ],
    );
  }

  gameOver() {
    if (_timer.isActive) {
      _timer.cancel();
    }
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("GameOver"),
          content: Text("ゲームオーバー！"),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('OK'),
              style: ElevatedButton.styleFrom(
                primary: Colors.blue,
                onPrimary: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  init();
                });
              },
            ),
          ],
        );
      },
    );
  }

  onUserControl(int dir) {
    if (dir == 0) {
      if (hitTest(0)) {
        setState(() {
          fixBlock();
          lineCheck();
          createBlock();
        });
      } else {
        setState(() {
          _block.posy++;
        });
      }
    } else if (dir == 1) {
      if (!hitTest(1)) {
        setState(() {
          _block.posx--;
        });
      }
    } else if (dir == 3) {
      if (!hitTest(3)) {
        setState(() {
          _block.posx++;
        });
      }
    } else if (dir == 2) {
      if (!_rotateFlag && !hitTest(-1)) {
        setState(() {
          _block.direction = (_block.direction + 1) % 4;
          _rotateFlag = true;
        });
      }
    }
  }
}
