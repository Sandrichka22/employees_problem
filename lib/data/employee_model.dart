import 'package:flutter/material.dart';

class Employee {
  Employee({this.id, this.projectId, this.start, this.end});

  int? id;
  int? projectId;
  DateTime? start;
  DateTime? end;

  var regExp = RegExp(r'(\d{4}-?\d\d-?\d\d(\s|T)\d\d:?\d\d:?\d\d)');

  factory Employee.fromList(List<dynamic> employeeData) {
    return Employee(
      id: employeeData[0],
      projectId: employeeData[1],
      start: DateTime.tryParse(employeeData[2].toString().trim()),
      end: employeeData[3].toString().trim() == 'NULL' ? DateTime.now() : DateTime.tryParse(employeeData[3].toString().trim()),
    );
  }

  int daysWorked() {
    return DateTimeRange(start: start!, end: end!).duration.inDays;
  }

  @override
  String toString() {
    return 'Employee{id: $id, projectId: $projectId, start: $start, end: $end}';
  }
}
