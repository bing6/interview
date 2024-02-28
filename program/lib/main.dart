import 'dart:convert';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic viewData;

  // 将原数据转换为动态表单数据
  // 用户界面将按此数据结构构建
  dynamic createDynamicFormData(dynamic data) {
    List<dynamic> items = <dynamic>[];

    void loop({
      required dynamic source,
      String path = '',
      String group = '',
    }) {
      for (var key in source.keys) {
        var t = path.isEmpty ? key : [path, key].join('.');
        if (source[key] is Map) {
          loop(source: source[key], path: t);
        } else if (source[key] is List) {
          var sub = source[key].map((i) {
            return {
              'ctrl_key': TextEditingController(text: i.keys.first),
              'ctrl_val': TextEditingController(text: i[i.keys.first]),
            };
          }).toList();
          items.add({
            'key': t,
            'name': key,
            'val': source[key],
            'type': 'list',
            'sub': sub,
          });
        } else {
          items.add({
            'key': t,
            'name': key,
            'val': source[key],
            'type': 'text',
            'ctrl': TextEditingController(text: source[key].toString()),
          });
        }
      }
    }

    loop(source: data);
    return {'items': items};
  }

  // 将表单数据转换为元数据，实现编辑修改功能
  void output() {
    dynamic result = {};

    for (var entry in viewData['items']) {
      if (entry['type'] == 'text') {
        setPathByValue(result, entry['key'], entry['ctrl'].text);
      } else {
        for (var i = 0; i < entry['sub'].length; i++) {
          var k = entry['sub'][i]['ctrl_key'].text;
          var v = entry['sub'][i]['ctrl_val'].text;
          var path = '${entry['key']}.#$i.$k';
          setPathByValue(result, path, v);
        }
      }
    }

    debugPrint('Data:${json.encode(result)}');
  }

  List<dynamic> filterByType(String type) {
    return viewData['items'].where((e) {
      return e['type'] == type;
    }).toList();
  }

  void removeGroupItem(String key, int index) {
    var dataItem = viewData['items'].where((e) {
      return e['key'] == key;
    });
    dataItem.first['sub'].removeAt(index);
    setState(() {});
  }

  void addGroupItem(String key) {
    var dataItem = viewData['items'].where((e) {
      return e['key'] == key;
    });
    dataItem.first['sub'].add({
      'ctrl_key': TextEditingController(),
      'ctrl_val': TextEditingController(),
    });
    setState(() {});
  }

  void setPathByValue(dynamic output, String path, String value) {
    var parts = path.toString().split('.');
    dynamic target = output;
    // var last = '';

    for (var i = 0; i < parts.length; i++) {
      var item = parts[i];

      if (i + 1 == parts.length) {
        target[item] = value;
        break;
      }

      if (item.startsWith('#')) {
        target.add({});
        target = target.last;
      } else {
        if (!target.containsKey(item)) {
          if (i + 1 <= parts.length && parts[i + 1].startsWith('#')) {
            target[item] = [];
          } else {
            target[item] = {};
          }
        }
        target = target[item];
      }
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    Map<String, dynamic> data = {
      // Map<String, Map<String, String>> '10%20%30%' 可以编辑
      // TODO:
      // 这里在原数据定义可能有问题:
      // 前: '前年度/2年度前/3年度前', '10%20%30%'
      // 后: '前年度/2年度前/3年度前': '10%20%30%'
      // 如果不修改可以判断类型HashSet来取值
      // 但根据整体结构与注视认为是编辑时写错了字符
      '中途採用比率': {'前年度/2年度前/3年度前': '10%20%30%'},
      '中途採用比率2': {'前年度/2年度前/3年度前': '10%20%30%'},
      // Map<String, String> value(如：'18.5年') 可以编辑
      '正社員の平均継続勤務年数': '18.5年',
      '従業員の平均年齢': '50.5岁',
      '月平均所定外労働時間': '18時間',
      '平均の法定時間外労働60時間以上の労働者の数': '15人',
      // Map<String, List<Map<String, String>>> List<Map<String, String>> 可以编辑，可删除 Map<String, String>，并且可以无限增加 Map<String, String>
      '育児休業取得率（男性）': [
        {'正社員': '34%'},
        {'専門職': '50%'},
      ],
      '育児休業取得率（女性）': [
        {'正社員': '34%'},
        {'専門職': '50%'},
      ],
    };

    viewData = createDynamicFormData(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(onPressed: output, icon: const Icon(Icons.output)),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(50),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._standard(),
              ..._group(),
            ],
          ),
        ),
      ),
    );
  }

  // 根据需求只可修改值的界面
  List<Widget> _standard() {
    if (viewData == null) return [];
    return [
      const Padding(
        padding: EdgeInsets.only(top: 30, bottom: 30),
        child: Text('Standard:'),
      ),
      ...filterByType('text').map<Widget>((e) {
        return SizedBox(
          height: 35,
          width: double.infinity,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${e['name']}:'),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: e['ctrl'],
                ),
              ),
            ],
          ),
        );
      }).toList()
    ];
  }

  // 根据需求可以修改键或值的界面
  List<Widget> _group() {
    // return [];
    if (viewData == null) return [];
    var widgets = <Widget>[];
    var res = filterByType('list');

    for (var entry in res) {
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 30),
        child: Row(
          children: [
            Text('${entry['key']}:'),
            IconButton(
              onPressed: () {
                addGroupItem(entry['key']);
              },
              icon: const Icon(
                Icons.add,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ));

      for (var i = 0; i < entry['sub'].length; i++) {
        var itemData = entry['sub'][i];
        var itemWidget = SizedBox(
          height: 30,
          width: double.infinity,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: itemData["ctrl_key"],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: itemData['ctrl_val'],
                ),
              ),
              IconButton(
                onPressed: () {
                  removeGroupItem(entry['key'], i);
                },
                icon: const Icon(
                  Icons.remove,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        );

        widgets.add(itemWidget);
      }
    }

    return widgets;
  }
}
