import 'package:canxe/common/widget/edit_table/common_child_table.dart';

import '../../data/cloud_obj.dart';
import '../../loadingstate/loading_stream_builder.dart';
import '../../utils.dart';
import '../../widget/edit_table/child_param.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../pdf/no_op_create_pdf.dart'
    if (dart.library.html) '../../pdf/pdf_creator.dart' as create_pdf;
import '../../data/cloud_table.dart';
import '../../utils/auto_form.dart';
import '../common.dart';
import 'edit_table_wrapper.dart';
import 'parent_param.dart';

class SelectedIndexChangeNotifier extends ValueNotifier<int> {
  SelectedIndexChangeNotifier(int value) : super(value);
}

class ChildEditTable<SchemaAndData> extends StatefulWidget {
  CollectionReference databaseRef;

  ChildEditTable(this.databaseRef);

  @override
  _ChildEditTableState createState() => _ChildEditTableState();
}

class _ChildEditTableState
    extends StreamStatefulChildState<ChildEditTable, SchemaAndData> {
  SelectedIndexChangeNotifier _selectedIndexChangeNotifier =
      SelectedIndexChangeNotifier(null);

  String inducedField(val, InputInfo inputInfo) {
    var calculated;
    if (val != null) {
      calculated =
          inputInfo.optionMap == null ? null : inputInfo.optionMap[val];
    }
    return calculated == null ? '${toText(context, val ?? '')}' : '$calculated';
  }

  @override
  Widget delegateBuild(BuildContext context) {
    _selectedIndexChangeNotifier.value = null;
    ParentParam parentParam = Provider.of<ParentParam>(context, listen: false);
    var schemaAndData = data;
    TableWidthAndSize tableWidthAndSize = getEditTableColWidths(
        context, schemaAndData.cloudTableSchema.inputInfoMap);
    return Material(
      child: ChangeNotifierProvider(
          create: (BuildContext context) {
            return _selectedIndexChangeNotifier;
          },
          child: Column(children: [
            Container(
                width: tableWidthAndSize.width,
                child: Consumer<SelectedIndexChangeNotifier>(
                  builder: (BuildContext context,
                      SelectedIndexChangeNotifier selectedIndexNotifier,
                      Widget child) {
                    return Table(
                        columnWidths: tableWidthAndSize.colWidths,
                        border: TableBorder(
                            top: EDIT_TABLE_BORDER_SIDE,
                            bottom: EDIT_TABLE_BORDER_SIDE,
                            horizontalInside: EDIT_TABLE_BORDER_SIDE),
                        children:
                            schemaAndData.data.asMap().entries.map((entry) {
                          int index = entry.key;
                          CloudObject eachRowMap = entry.value;
                          var dataRow = TableRow(
                              children: schemaAndData
                                  .cloudTableSchema.inputInfoMap.keys
                                  .map((field) {
                            InputInfo inputInfo = schemaAndData
                                .cloudTableSchema.inputInfoMap[field];
                            return TableCell(
                                child: InkWell(
                              onTap: () {
                                selectedIndexNotifier.value = index;
                              },
                              child: Container(
                                color: index == selectedIndexNotifier.value
                                    ? Colors.red[50]
                                    : Colors.white,
                                alignment: schemaAndData.cloudTableSchema
                                            .inputInfoMap[field].dataType ==
                                        DataType.int
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Text(
                                  inducedField(
                                      eachRowMap.dataMap[field], inputInfo),
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ));
                          }).toList());
                          return dataRow;
                        }).toList());
                  },
                )),
            Consumer<DatabasePagerNotifier>(builder: (BuildContext context,
                DatabasePagerNotifier databasePagerNotifier, Widget child) {
              return Consumer<SelectedIndexChangeNotifier>(builder:
                  (BuildContext context,
                      SelectedIndexChangeNotifier selectedIndexChangeNotifier,
                      Widget child) {
//                print(
//                    '${isLoading} ${parentParam.sortKeyDescending} ${schemaAndData.data.first.dataMap[parentParam.sortKey]}');
//                  ' ${StackTrace.current}');
                if (schemaAndData.data.length == 0) {
                  return CommonButton.getButton(context, () {
                    databasePagerNotifier.value = ChildParam();
                  }, title: 'Về trang đầu');
                }
                var beforeQuery =
                    applyFilterToQuery(widget.databaseRef, parentParam)
                        .orderBy(parentParam.sortKey,
                            descending: parentParam.sortKeyDescending)
                        .endBefore([
                  schemaAndData.data.first.dataMap[parentParam.sortKey]
                ]).limit(1) as Query;
                var afterQuery =
                    applyFilterToQuery(widget.databaseRef, parentParam)
                        .orderBy(parentParam.sortKey,
                            descending: parentParam.sortKeyDescending)
                        .startAfter([
                  schemaAndData.data.last.dataMap[parentParam.sortKey]
                ]).limit(1) as Query;
                return Column(children: [
                  SizedBox(
                    width: screenWidth(context) * 0.3,
                    height: screenHeight(context) * 0.1,
                    child: tableOfTwo({
                      'Trường sắp xếp':
                          '${schemaAndData.cloudTableSchema.inputInfoMap[parentParam.sortKey].fieldDes}-${parentParam.sortKeyDescending ? "Giảm dần" : "Tăng dần"}',
                      'Hiển thị sau': toText(
                          context, databasePagerNotifier.value.startAfter),
                      'Hiển thị trước': toText(
                          context, databasePagerNotifier.value.endBefore),
                      'Số lượng hiển thị': '${schemaAndData.data.length}',
                    }, boldRight: true),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StreamProvider<bool>.value(
                        value: isLoading
                            ? Stream<bool>.value(false)
                            : beforeQuery.snapshots().map((event) {
                                return event.documents.length > 0;
                              }),
                        child: Builder(
                          builder: (BuildContext context) {
                            bool existBefore =
                                Provider.of<bool>(context) ?? false;
                            return CommonButton.getButton(context, () {
                              // go back
                              databasePagerNotifier.value = ChildParam(
                                  endBefore: schemaAndData
                                      .data.first.dataMap[parentParam.sortKey]);
                            },
                                title: "",
                                iconData:
                                    existBefore ? Icons.navigate_before : null,
                                isEnabled: existBefore);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                      StreamProvider<bool>.value(
                        value: isLoading
                            ? Stream<bool>.value(false)
                            : afterQuery
                                .snapshots()
                                .map((event) => event.documents.length > 0),
                        child: Builder(builder: (BuildContext context) {
                          bool existAfter = Provider.of<bool>(context) ?? false;
                          return CommonButton.getButton(context, () {
                            // go forward
                            databasePagerNotifier.value = ChildParam(
                                startAfter: schemaAndData
                                    .data.last.dataMap[parentParam.sortKey]);
                          },
                              title: "",
                              iconData: existAfter ? Icons.navigate_next : null,
                              isEnabled: existAfter);
                        }),
                      ),
                    ],
                  ),
                ]);
              });
            }),
            SizedBox(
              height: 20,
            ),
            Consumer<SelectedIndexChangeNotifier>(builder:
                (BuildContext context,
                    SelectedIndexChangeNotifier selectedIndexChangeNotifier,
                    Widget child) {
              PrintInfo defaultPrint = schemaAndData.cloudTableSchema.printInfos
                  .where((element) => element.isDefault)
                  .toList()[0];
              List<PrintInfo> otherPrints = schemaAndData
                  .cloudTableSchema.printInfos
                  .where((element) => !element.isDefault)
                  .toList();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ChildTableUtils.printDefault(
                      context, widget.databaseRef, defaultPrint, parentParam),
                  otherPrints.length > 0
                      ? DropdownButton(
                          items: otherPrints
                              .map((printInfo) => DropdownMenuItem(
                                    child: ChildTableUtils.printDefault(
                                        context,
                                        widget.databaseRef,
                                        printInfo,
                                        parentParam),
                                  ))
                              .toList(),
                          onChanged: (value) {},
                        )
                      : null,
                  ChildTableUtils.newButton(
                      context, widget.databaseRef, schemaAndData),
                  ChildTableUtils.editButton(context, widget.databaseRef,
                      schemaAndData, selectedIndexChangeNotifier.value),
                  ChildTableUtils.deleteButton(context, widget.databaseRef,
                      schemaAndData, selectedIndexChangeNotifier.value)
                ].where((element) => element != null).toList(),
              );
            })
          ])),
    );
  }
}
