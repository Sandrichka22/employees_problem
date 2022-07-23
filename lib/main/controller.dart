import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tuple/tuple.dart';

import '../data/employee_model.dart';

class MainController extends GetxController {
  static MainController get to => Get.find();

  PlatformFile? _pickedFile;
  final FileType _pickingType = FileType.custom;
  Tuple2<Tuple2, int>? pairWorkedMost;

  List<String> tableTitles = ['Employee ID #1', 'Employee ID #2', 'Project ID', 'Days worked'];
  List<List<String>> tableRows = [];

  void openFileExplorer() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _pickingType,
        allowMultiple: false,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        tableRows.clear();
        pairWorkedMost = null;
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

    if (_pickedFile != null) {
      _openFile(_pickedFile!.path);
      print("File path ${_pickedFile?.path}");
      print(_pickedFile?.extension);
    }
  }

  void _openFile(filepath) async {
    File f = File(filepath);

    print("CSV to List of Data");

    final input = f.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    print(fields);

    _findThePair(fields);
  }

  /// Retrieves the pair of employees that have worked together (at the same time) on common projects,
  /// the longest period of time (longest of the periods that all other pairs have worked together on common projects).
  ///
  /// The input [employees] list consists of all the employees (rows) read from the CSV file, where every row contains the
  /// information [EmpID, ProjectID, DateFrom, DateTo] for the employee
  ///
  ///
  /// The main idea behind the solution is to traverse the list of employees, take the project id they were working on,
  /// and use this project id as a key to a map where we sort all employees in different projects.
  ///
  ///
  /// Example of projects map:
  ///
  /// projects = {
  ///   "projectId#1":{
  ///     "userID#1": {
  ///       "start": Date,
  ///       "end": Date},
  ///      "userID#5": {
  ///         "start": Date,
  ///         "end": Date
  ///         }
  ///    }
  ///  "projectId#2":{
  ///     "userID#1": {
  ///       "start": Date,
  ///       "end": Date},
  ///      "userID#9": {
  ///         "start": Date,
  ///         "end": Date
  ///         }
  ///    }
  ///    }
  ///
  /// While adding an employee to a corresponding project key, check if this employee has an overlapping
  /// period of time with other employees that have also worked on the same project (are in the same map).
  ///
  ///
  /// If there is an overlap, save this pair in a separate map, which has the pair of employees as key,
  /// and another map as value, which stores the total days they have worked together in "total"
  /// and the list of projects they have worked together in "projects"
  ///
  /// Example of pairs map:
  ///
  /// pairs = {
  ///   "userID#1, user#4": {
  ///     "total": daysTotal,
  ///     "projects" : [[projectID, days], [projectID, days]]
  ///     }
  /// }
  ///
  /// Keep track of the pair that have worked the longest in [pairWorkedMost]
  ///
  /// pairWorkedMost => Tuple2(Tuple2(userID#1, userID#2), daysTotal)
  //
  void _findThePair(List<List<dynamic>> employees) {
    Map<int, Map<int, Map<String, DateTime>>> projects = {};
    Map<Tuple2<int, int>, Map<String, Object>> pairs = {};

    for (int i = 0; i < employees.length; i++) {
      Employee employee = Employee.fromList(employees[i]);

      projects.update(employee.projectId!, (allUsersThatWorkedOnProject) {
        allUsersThatWorkedOnProject.forEach((key, value) {
          int overlap = findOverlapInDays(employee.start!, employee.end!, value['start']!, value['end']!);
          if (overlap > 0) {
            print('>>>> we found an overlap');

            pairs.update(Tuple2(employee.id!, key), (value) {
              value.update('total', (value) => (value as int) + overlap, ifAbsent: () => overlap);
              value.update('projects', (value) {
                (value as List).add([employee.projectId, overlap]);
                return value;
              },
                  ifAbsent: () => [
                        [employee.projectId, overlap]
                      ]);
              return value;
            }, ifAbsent: () {
              // check to see if it exists a tuple that's consisted of the same pair of employees, but in opposite tuple order
              return pairs.update(Tuple2(key, employee.id!), (value) {
                value.update('total', (value) => (value as int) + overlap, ifAbsent: () => overlap);
                value.update('projects', (value) {
                  (value as List).add([employee.projectId, overlap]);
                  return value;
                },
                    ifAbsent: () => [
                          [employee.projectId, overlap]
                        ]);
                return value;
              },
                  ifAbsent: () => {
                        'total': overlap,
                        'projects': [
                          [employee.projectId, overlap]
                        ]
                      });
            });

            Tuple2 currentPair = Tuple2(employee.id!, key);
            if (pairWorkedMost == null) {
              pairWorkedMost = Tuple2(currentPair, pairs[currentPair]!['total'] as int);
            } else {
              if (pairWorkedMost!.item2 < (pairs[currentPair]!['total'] as int)) {
                pairWorkedMost = Tuple2(currentPair, pairs[currentPair]!['total'] as int);
              }
            }
          }
        });

        allUsersThatWorkedOnProject[employee.id!] = <String, DateTime>{'start': employee.start!, 'end': employee.end!};
        return allUsersThatWorkedOnProject;
      },
          ifAbsent: () => {
                employee.id!: <String, DateTime>{'start': employee.start!, 'end': employee.end!}
              });
    }

    print('>>>>>>>>> Employees sorted by projects: $projects');
    print('>>>>>>>>> Pairs: $pairs');
    print('>>>>>>>>> The pair that worked most: ${pairWorkedMost!.item1.toString()}, duration: ${pairWorkedMost!.item2}');

    setResultTableRows(pairs);
    update();
  }

  /// Just a helper function to put the employees ids, and all the projects the pair has worked together
  /// with their durations in a list convenient to the required UI representation
  ///
  /// Employee ID #1, Employee ID #2, Project ID, Days worked
  ///
  /// Every item in the list is a list itself representing a different project the pair has worked together and its duration:
  ///
  ///
  /// For example: [[ID#1, ID#2, projectID, durationInDays]]
  ///
  void setResultTableRows(Map<Tuple2<int, int>, Map<String, dynamic>> pairs) {
    int employee1 = pairWorkedMost!.item1.item1;
    int employee2 = pairWorkedMost!.item1.item2;

    pairs[Tuple2(employee1, employee2)]!['projects'].forEach((value) {
      tableRows.add([employee1.toString(), employee2.toString(), value[0].toString(), value[1].toString()]);
    });
  }

  /// Finds overlap between two periods using the following logic:
  ///
  /// (firstStart <= secondEnd) and (firstEnd >= secondStart)
  ///
  int findOverlapInDays(DateTime firstStart, DateTime firstEnd, DateTime secondStart, DateTime secondEnd) {
    int daysOverlap = 0;

    if ((firstStart.isBefore(secondEnd) || firstStart.isAtSameMomentAs(secondEnd)) && (firstEnd.isAfter(secondStart) || firstEnd.isAtSameMomentAs(secondStart))) {
      // there is an overlap

      DateTime latestStart = firstStart.isAfter(secondStart) ? firstStart : secondStart;
      DateTime earliestEnd = firstEnd.isBefore(secondEnd) ? firstEnd : secondEnd;

      if (latestStart.isAfter(earliestEnd)) {
        return DateTimeRange(start: earliestEnd, end: latestStart).duration.inDays;
      } else {
        return DateTimeRange(start: latestStart, end: earliestEnd).duration.inDays;
      }
    }

    return daysOverlap;
  }
}
