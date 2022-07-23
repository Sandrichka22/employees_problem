import 'package:employees_problem/main/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainPage extends GetView {
  const MainPage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    final MainController controller = Get.put(MainController());

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: GetBuilder<MainController>(builder: (controller) {
        return Center(
          child: FractionallySizedBox(
            widthFactor: 0.8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (controller.pairWorkedMost == null) const Text('Pick a CSV file on the floating action button'),
                if (controller.pairWorkedMost != null)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('The pair that worked most together is: ${controller.pairWorkedMost!.item1.item1} & ${controller.pairWorkedMost!.item1.item2}'),
                  ),
                if (controller.pairWorkedMost != null)
                  Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      TableRow(
                          children: controller.tableTitles
                              .map((title) => TableCell(
                                    child: Container(
                                      color: Colors.blue,
                                      child: Center(
                                          child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          title,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      )),
                                    ),
                                  ))
                              .toList()),
                      ...controller.tableRows
                          .map((rows) => TableRow(
                              children: rows
                                  .map((value) => TableCell(
                                        child: Container(
                                          color: Colors.white,
                                          child: Center(
                                              child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              value,
                                              style: TextStyle(color: Colors.blue),
                                            ),
                                          )),
                                        ),
                                      ))
                                  .toList()))
                          .toList(),
                    ],
                  ),
                if (controller.pairWorkedMost != null)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: RichText(
                      text: TextSpan(children: [
                        const TextSpan(
                          text: 'They have worked together for ',
                          style: TextStyle(color: Colors.black),
                        ),
                        TextSpan(
                          text: '${controller.pairWorkedMost!.item2} ',
                          style: const TextStyle(color: Colors.blue, fontSize: 16),
                        ),
                        const TextSpan(
                          text: 'days total',
                          style: TextStyle(color: Colors.black),
                        ),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.openFileExplorer,
        tooltip: 'Pick CSV File',
        child: const Icon(Icons.file_upload),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
