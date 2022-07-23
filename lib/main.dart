import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:employees_problem/data/employee_model.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuple/tuple.dart';

import 'main/view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employees Problem',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MainPage(title: 'Flutter Employees Problem'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PlatformFile? _pickedFile;
  final FileType _pickingType = FileType.custom;
  late List<List<dynamic>> employeesData;

  Tuple2<Tuple2, int>? pairWorkedMost;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (pairWorkedMost != null) Text('The pair that worked most together is: ${pairWorkedMost!.item1.item1} & ${pairWorkedMost!.item1.item2}'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openFileExplorer,
        tooltip: 'Pick CSV File',
        child: const Icon(Icons.file_upload),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _openFileExplorer() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: false,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        _pickedFile = result.files.single;
      } else {
        // User canceled the picker
        return;
      }
    } on PlatformException catch (e) {
      print('Unsupported operation ${e.toString()}');
    } catch (ex) {
      print(ex);
    }

    if (!mounted) return;
    setState(() {
      if (_pickedFile != null) {
        openFile(_pickedFile!.path);
        print("File path ${_pickedFile?.path}");
        print(_pickedFile?.extension);
      }
    });
  }

  void openFile(filepath) async {
    File f = File(filepath);

    print("CSV to List of Data");

    final input = f.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    print(fields);

    setState(() {
      employeesData = fields;
    });

    findThePair(fields);
  }

  /// Retrieves the pair of employees that have worked together (at the same time) on common projects,
  /// the longest period of time (longest of the periods that all other pairs have worked together on common projects).
  ///
  /// The input [employees] list consists of all the employees (rows) read from the CSV file, where every row contains the
  /// information [EmpID, ProjectID, DateFrom, DateTo] for the employee
  //
  List<dynamic> findThePair(List<List<dynamic>> employees) {
    Map<int, Map<int, Map<String, DateTime>>> projects = {};
    Map<Tuple2<int, int>, Map<String, dynamic>> pairs = {};

    for (int i = 0; i < employees.length; i++) {
      Employee employee = Employee.fromList(employees[i]);

      projects.update(employee.projectId!, (usersThatWorkedOnProject) {
        usersThatWorkedOnProject.forEach((key, value) {
          int overlap = findOverlap(employee.start!, employee.end!, value['start']!, value['end']!);
          if (overlap > 0) {
            pairs.update(Tuple2(employee.id!, key), (value) {
              value.update('total', (value) => value + overlap);
              value.update('projects', (value) => {'projectId': overlap});
              return value;
            },
                ifAbsent: () => {
                      'total': overlap,
                      'projects': {employee.projectId, overlap}
                    });

            Tuple2 currentPair = Tuple2(employee.id!, key);
            if (pairWorkedMost == null) {
              pairWorkedMost = Tuple2(currentPair, pairs[currentPair]!['total']);
            } else {
              if (pairWorkedMost!.item2 < pairs[currentPair]!['total']) {
                pairWorkedMost = Tuple2(currentPair, pairs[currentPair]!['total']);
              }
            }
          }
        });

        usersThatWorkedOnProject[employee.id!] = <String, DateTime>{'start': employee.start!, 'end': employee.end!};
        return usersThatWorkedOnProject;
      },
          ifAbsent: () => {
                employee.id!: <String, DateTime>{'start': employee.start!, 'end': employee.end!}
              });
    }

    print('>>>>>>>>> projects: $projects');
    print('>>>>>>>>> pairs: $pairs');
    setState(() {});
    print('>>>>>>>>> pairs that worked most: $pairWorkedMost');
    return [];
  }

  /// Finds overlap between two periods using the following logic
  /// (firstStart <= secondEnd) and (firstEnd >= secondStart)
  ///
  int findOverlap(DateTime firstStart, DateTime firstEnd, DateTime secondStart, DateTime secondEnd) {
    int daysOverlap = 0;

    if ((firstStart.isBefore(secondEnd) || firstStart.isAtSameMomentAs(secondEnd)) && (firstEnd.isAfter(secondStart) || firstEnd.isAtSameMomentAs(secondStart))) {
      // there is an overlap
      print('>>>>>>>> there is an overlap >>>>>>');
      DateTime latestStart = firstStart.isAfter(secondStart) ? firstStart : secondStart;
      DateTime earliestEnd = firstEnd.isBefore(secondEnd) ? firstEnd : secondEnd;

      // print('>>>>>>>> latest Start: ${DateFormat('yyyy-MM-dd').format(latestStart)} >>>>>>');
      // print('>>>>>>>> latest End: ${DateFormat('yyyy-MM-dd').format(earliestEnd)} >>>>>>');

      if (latestStart.isAfter(earliestEnd)) {
        return DateTimeRange(start: earliestEnd, end: latestStart).duration.inDays;
      } else {
        return DateTimeRange(start: latestStart, end: earliestEnd).duration.inDays;
      }
    }

    return daysOverlap;
  }
}
