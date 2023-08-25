import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:zsdk/zsdk.dart' as Printer;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

const String btnPrintPdfFileOverTCPIP = 'btnPrintPdfFileOverTCPIP';
const String btnPrintZplFileOverTCPIP = 'btnPrintZplFileOverTCPIP';
const String btnPrintZplDataOverTCPIP = 'btnPrintZplDataOverTCPIP';
const String btnCheckPrinterStatus = 'btnCheckPrinterStatus';
const String btnGetPrinterSettings = 'btnGetPrinterSettings';
const String btnSetPrinterSettings = 'btnSetPrinterSettings';
const String btnResetPrinterSettings = 'btnResetPrinterSettings';
const String btnDoManualCalibration = 'btnDoManualCalibration';
const String btnPrintConfigurationLabel = 'btnPrintConfigurationLabel';

class MyApp extends StatefulWidget {
  final Printer.ZSDK zsdk = Printer.ZSDK();

  MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

enum PrintStatus {
  PRINTING,
  SUCCESS,
  ERROR,
  NONE,
}

enum CheckingStatus {
  CHECKING,
  SUCCESS,
  ERROR,
  NONE,
}

enum SettingsStatus {
  GETTING,
  SETTING,
  SUCCESS,
  ERROR,
  NONE,
}

enum CalibrationStatus {
  CALIBRATING,
  SUCCESS,
  ERROR,
  NONE,
}

class _MyAppState extends State<MyApp> {
  final addressIpController = TextEditingController(text: "10.0.0.100");
  final addressPortController = TextEditingController();
  final pathController = TextEditingController();
  final zplDataController = TextEditingController(
      text: '^XA^FO17,16^GB379,371,8^FS^FT65,255^A0N,135,134^FDTEST^FS^XZ');
  final widthController = TextEditingController();
  final heightController = TextEditingController();
  final dpiController = TextEditingController();

  final darknessController = TextEditingController();
  final printSpeedController = TextEditingController();
  final tearOffController = TextEditingController();
  final printWidthController = TextEditingController();
  final labelLengthController = TextEditingController();
  final labelLengthMaxController = TextEditingController();
  final labelTopController = TextEditingController();
  final leftPositionController = TextEditingController();
  Printer.MediaType? selectedMediaType;
  Printer.PrintMethod? selectedPrintMethod;
  Printer.ZPLMode? selectedZPLMode;
  Printer.PowerUpAction? selectedPowerUpAction;
  Printer.HeadCloseAction? selectedHeadCloseAction;
  Printer.PrintMode? selectedPrintMode;
  Printer.ReprintMode? selectedReprintMode;

  Printer.PrinterSettings? settings;

  Printer.Orientation printerOrientation = Printer.Orientation.LANDSCAPE;
  String? message;
  String? statusMessage;
  String? settingsMessage;
  String? calibrationMessage;
  PrintStatus printStatus = PrintStatus.NONE;
  CheckingStatus checkingStatus = CheckingStatus.NONE;
  SettingsStatus settingsStatus = SettingsStatus.NONE;
  CalibrationStatus calibrationStatus = CalibrationStatus.NONE;
  String? filePath;
  String? zplData;

  @override
  void initState() {
    super.initState();
  }

  String getName<T>(T value) {
    String name = 'Unknown';
    if (value is Printer.HeadCloseAction) name = value.name;
    if (value is Printer.MediaType) name = value.name;
    if (value is Printer.PowerUpAction) name = value.name;
    if (value is Printer.PrintMethod) name = value.name;
    if (value is Printer.PrintMode) name = value.name;
    if (value is Printer.ReprintMode) name = value.name;
    if (value is Printer.ZPLMode) name = value.name;
    return name;
  }

  List<DropdownMenuItem<T>> generateDropdownItems<T>(List<T> values) {
    List<DropdownMenuItem<T>> items = [];
    for (var value in values) {
      items.add(DropdownMenuItem<T>(
        child: Text(getName(value)),
        value: value,
      ));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text('Billet Tracking'),
      ),
      body: Container(
        padding: const EdgeInsets.all(8),
        child: Scrollbar(
            child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Label Printing',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(
                color: Colors.transparent,
              ),
              const SizedBox(
                height: 6,
              ),
              Container(
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'ZPL data to print',
                        style: TextStyle(fontSize: 16),
                      ),
                      TextField(
                        controller: zplDataController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.red, //this has no effect
                            ),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          hintText: "Border decoration text ...",
                        ),
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: <Widget>[
                      const Text(
                        'Printer address',
                        style: TextStyle(fontSize: 16),
                      ),
                      TextField(
                        controller: addressIpController,
                        decoration:
                            const InputDecoration(labelText: "IP address"),
                      ),
                      TextField(
                        controller: addressPortController,
                        decoration:
                            const InputDecoration(labelText: "Printer port"),
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      Visibility(
                        child: Column(
                          children: <Widget>[
                            Text(
                              "$statusMessage",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: getCheckStatusColor(checkingStatus)),
                            ),
                            const SizedBox(
                              height: 16,
                            ),
                          ],
                        ),
                        visible: checkingStatus != CheckingStatus.NONE,
                      ),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: ElevatedButton(
                              child: Text(
                                "Check printer status".toUpperCase(),
                                textAlign: TextAlign.center,
                              ),
                              style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.orange),
                                  textStyle: MaterialStateProperty.all(
                                      const TextStyle(color: Colors.white))),
                              onPressed:
                                  checkingStatus == CheckingStatus.CHECKING
                                      ? null
                                      : () => onClick(btnCheckPrinterStatus),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              Visibility(
                child: Column(
                  children: <Widget>[
                    Text(
                      "$message",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getPrintStatusColor(printStatus)),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                  ],
                ),
                visible: printStatus != PrintStatus.NONE,
              ),
              ElevatedButton(
                child: Text(
                  "Test Print".toUpperCase(),
                  textAlign: TextAlign.center,
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.cyan),
                    textStyle: MaterialStateProperty.all(
                        const TextStyle(color: Colors.white))),
                onPressed: printStatus == PrintStatus.PRINTING
                    ? null
                    : () => onClick(btnPrintConfigurationLabel),
              ),
              SizedBox(
                height: 6,
              ),
              ElevatedButton(
                child: Text(
                  "Print zpl data".toUpperCase(),
                  textAlign: TextAlign.center,
                ),
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(Colors.blueAccent),
                    textStyle: MaterialStateProperty.all(
                        const TextStyle(color: Colors.white))),
                onPressed: printStatus == PrintStatus.PRINTING
                    ? null
                    : () => onClick(btnPrintZplDataOverTCPIP),
              ),
              const SizedBox(
                height: 100,
              ),
            ],
          ),
        )),
      ),
    );
  }

  Color getPrintStatusColor(PrintStatus status) {
    switch (status) {
      case PrintStatus.PRINTING:
        return Colors.blue;
      case PrintStatus.SUCCESS:
        return Colors.green;
      case PrintStatus.ERROR:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color getCheckStatusColor(CheckingStatus status) {
    switch (status) {
      case CheckingStatus.CHECKING:
        return Colors.blue;
      case CheckingStatus.SUCCESS:
        return Colors.green;
      case CheckingStatus.ERROR:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color getSettingsStatusColor(SettingsStatus status) {
    switch (status) {
      case SettingsStatus.GETTING:
      case SettingsStatus.SETTING:
        return Colors.blue;
      case SettingsStatus.SUCCESS:
        return Colors.green;
      case SettingsStatus.ERROR:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Color getCalibrationStatusColor(CalibrationStatus status) {
    switch (status) {
      case CalibrationStatus.CALIBRATING:
        return Colors.blue;
      case CalibrationStatus.SUCCESS:
        return Colors.green;
      case CalibrationStatus.ERROR:
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  void updateSettings(Printer.PrinterSettings? newSettings) {
    settings = newSettings;

    darknessController.text = "${settings?.darkness ?? ""}";
    printSpeedController.text = "${settings?.printSpeed ?? ""}";
    tearOffController.text = "${settings?.tearOff ?? ""}";
    printWidthController.text = "${settings?.printWidth ?? ""}";
    labelLengthController.text = "${settings?.labelLength ?? ""}";
    labelLengthMaxController.text = "${settings?.labelLengthMax ?? ""}";
    labelTopController.text = "${settings?.labelTop ?? ""}";
    leftPositionController.text = "${settings?.leftPosition ?? ""}";
    selectedMediaType = settings?.mediaType;
    selectedPrintMethod = settings?.printMethod;
    selectedZPLMode = settings?.zplMode;
    selectedPowerUpAction = settings?.powerUpAction;
    selectedHeadCloseAction = settings?.headCloseAction;
    selectedPrintMode = settings?.printMode;
    selectedReprintMode = settings?.reprintMode;
  }

  onClick(String id) async {
    try {
      switch (id) {
        case btnDoManualCalibration:
          setState(() {
            calibrationMessage = "Starting manual callibration...";
            calibrationStatus = CalibrationStatus.CALIBRATING;
          });
          widget.zsdk
              .doManualCalibrationOverTCPIP(
            address: addressIpController.text,
            port: int.tryParse(addressPortController.text),
          )
              .then((value) {
            setState(() {
              calibrationStatus = CalibrationStatus.SUCCESS;
              calibrationMessage = "$value";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                calibrationMessage =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause} \n"
                    "${printerResponse.settings?.toString()}";
              } catch (e) {
                print(e);
                calibrationMessage = e.toString();
              }
            } on MissingPluginException catch (e) {
              calibrationMessage = "${e.message}";
            } catch (e) {
              calibrationMessage = e.toString();
            }
            setState(() {
              calibrationStatus = CalibrationStatus.ERROR;
            });
          });
          break;
        case btnGetPrinterSettings:
          setState(() {
            settingsMessage = "Getting printer settings...";
            settingsStatus = SettingsStatus.GETTING;
          });
          widget.zsdk
              .getPrinterSettingsOverTCPIP(
            address: addressIpController.text,
            port: int.tryParse(addressPortController.text),
          )
              .then((value) {
            setState(() {
              settingsStatus = SettingsStatus.SUCCESS;
              settingsMessage = "$value";
              updateSettings((Printer.PrinterResponse.fromMap(value)).settings);
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                settingsMessage =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause} \n"
                    "${printerResponse.settings?.toString()}";
              } catch (e) {
                print(e);
                settingsMessage = e.toString();
              }
            } on MissingPluginException catch (e) {
              settingsMessage = "${e.message}";
            } catch (e) {
              settingsMessage = e.toString();
            }
            setState(() {
              settingsStatus = SettingsStatus.ERROR;
            });
          });
          break;
        case btnSetPrinterSettings:
          setState(() {
            settingsMessage = "Setting printer settings...";
            settingsStatus = SettingsStatus.SETTING;
          });
          widget.zsdk
              .setPrinterSettingsOverTCPIP(
                  address: addressIpController.text,
                  port: int.tryParse(addressPortController.text),
                  settings: Printer.PrinterSettings(
                    darkness: double.tryParse(darknessController.text),
                    printSpeed: double.tryParse(printSpeedController.text),
                    tearOff: int.tryParse(tearOffController.text),
                    mediaType: selectedMediaType,
                    printMethod: selectedPrintMethod,
                    printWidth: int.tryParse(printWidthController.text),
                    labelLength: int.tryParse(labelLengthController.text),
                    labelLengthMax:
                        double.tryParse(labelLengthMaxController.text),
                    zplMode: selectedZPLMode,
                    powerUpAction: selectedPowerUpAction,
                    headCloseAction: selectedHeadCloseAction,
                    labelTop: int.tryParse(labelTopController.text),
                    leftPosition: int.tryParse(leftPositionController.text),
                    printMode: selectedPrintMode,
                    reprintMode: selectedReprintMode,
                  )
//            settings: Printer.PrinterSettings(
//              darkness: 10, //10
//              printSpeed: 6, //6
//              tearOff: 0,//0
//              mediaType: Printer.MediaType.MARK, //MARK
//              printMethod: Printer.PrintMethod.DIRECT_THERMAL, //DIRECT_THERMAL
//              printWidth: 568,//600
//              labelLength: 1202,//1202
//              labelLengthMax: 39,//39
//              zplMode: Printer.ZPLMode.ZPL_II,//ZPL II
//              powerUpAction: Printer.PowerUpAction.NO_MOTION,//NO MOTION
//              headCloseAction: Printer.HeadCloseAction.FEED,//FEED
//              labelTop: 0,//0
//              leftPosition: 0,//0
//              printMode: Printer.PrintMode.TEAR_OFF,//TEAR_OFF
//              reprintMode: Printer.ReprintMode.OFF,//OFF
//            )
//            settings: Printer.PrinterSettings(
//              darkness: 30, //10
//              printSpeed: 3, //6
//              tearOff: 100,//0
//              mediaType: Printer.MediaType.CONTINUOUS, //MARK
//              printMethod: Printer.PrintMethod.THERMAL_TRANS, //DIRECT_THERMAL
//              printWidth: 568,//600
//              labelLength: 1000,//1202
//              labelLengthMax: 30,//39
//              zplMode: Printer.ZPLMode.ZPL,//ZPL II
//              powerUpAction: Printer.PowerUpAction.FEED,//NO MOTION
//              headCloseAction: Printer.HeadCloseAction.NO_MOTION,//FEED
//              labelTop: 50,//0
//              leftPosition: 100,//0
//              printMode: Printer.PrintMode.CUTTER,//TEAR_OFF
//              reprintMode: Printer.ReprintMode.ON,//OFF
//            )
                  )
              .then((value) {
            setState(() {
              settingsStatus = SettingsStatus.SUCCESS;
              settingsMessage = "$value";
              updateSettings((Printer.PrinterResponse.fromMap(value)).settings);
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                settingsMessage =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause} \n"
                    "${printerResponse.settings?.toString()}";
              } catch (e) {
                print(e);
                settingsMessage = e.toString();
              }
            } on MissingPluginException catch (e) {
              settingsMessage = "${e.message}";
            } catch (e) {
              settingsMessage = e.toString();
            }
            setState(() {
              settingsStatus = SettingsStatus.ERROR;
            });
          });
          break;
        case btnResetPrinterSettings:
          setState(() {
            settingsMessage = "Setting default settings...";
            settingsStatus = SettingsStatus.SETTING;
          });
          widget.zsdk
              .setPrinterSettingsOverTCPIP(
                  address: addressIpController.text,
                  port: int.tryParse(addressPortController.text),
                  settings: Printer.PrinterSettings.defaultSettings())
              .then((value) {
            setState(() {
              settingsStatus = SettingsStatus.SUCCESS;
              settingsMessage = "$value";
              updateSettings((Printer.PrinterResponse.fromMap(value)).settings);
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                settingsMessage =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause} \n"
                    "${printerResponse.settings?.toString()}";
              } catch (e) {
                print(e);
                settingsMessage = e.toString();
              }
            } on MissingPluginException catch (e) {
              settingsMessage = "${e.message}";
            } catch (e) {
              settingsMessage = e.toString();
            }
            setState(() {
              settingsStatus = SettingsStatus.ERROR;
            });
          });
          break;
        case btnCheckPrinterStatus:
          setState(() {
            statusMessage = "Checking printer status...";
            checkingStatus = CheckingStatus.CHECKING;
          });
          widget.zsdk
              .checkPrinterStatusOverTCPIP(
            address: addressIpController.text,
            port: int.tryParse(addressPortController.text),
          )
              .then((value) {
            setState(() {
              checkingStatus = CheckingStatus.SUCCESS;
              Printer.PrinterResponse? printerResponse;
              if (value != null) {
                printerResponse = Printer.PrinterResponse.fromMap(value);
              }
              statusMessage =
                  "${printerResponse != null ? printerResponse.toMap() : value}";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                statusMessage =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause}";
              } catch (e) {
                print(e);
                statusMessage = e.toString();
              }
            } on MissingPluginException catch (e) {
              statusMessage = "${e.message}";
            } catch (e) {
              statusMessage = e.toString();
            }
            setState(() {
              checkingStatus = CheckingStatus.ERROR;
            });
          });
          break;
        case btnPrintConfigurationLabel:
          setState(() {
            message = "Print job started...";
            printStatus = PrintStatus.PRINTING;
          });
          widget.zsdk
              .printConfigurationLabelOverTCPIP(
            address: addressIpController.text,
            port: int.tryParse(addressPortController.text),
          )
              .then((value) {
            setState(() {
              printStatus = PrintStatus.SUCCESS;
              message = "$value";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                message =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause}";
              } catch (e) {
                print(e);
                message = e.toString();
              }
            } on MissingPluginException catch (e) {
              message = "${e.message}";
            } catch (e) {
              message = e.toString();
            }
            setState(() {
              printStatus = PrintStatus.ERROR;
            });
          });
          break;
        case btnPrintPdfFileOverTCPIP:
          if (Platform.isIOS) throw Exception("Not implemented for iOS");
          if (!pathController.text.endsWith(".pdf")) {
            throw Exception(
                "Make sure you properly write the path or selected a proper pdf file");
          }
          setState(() {
            message = "Print job started...";
            printStatus = PrintStatus.PRINTING;
          });
          widget.zsdk
              .printPdfFileOverTCPIP(
                  filePath: pathController.text,
                  address: addressIpController.text,
                  port: int.tryParse(addressPortController.text),
                  printerConf: Printer.PrinterConf(
                    cmWidth: double.tryParse(widthController.text),
                    cmHeight: double.tryParse(heightController.text),
                    dpi: double.tryParse(dpiController.text),
                    orientation: printerOrientation,
                  ))
              .then((value) {
            setState(() {
              printStatus = PrintStatus.SUCCESS;
              message = "$value";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                message =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause}";
              } catch (e) {
                print(e);
                message = e.toString();
              }
            } on MissingPluginException catch (e) {
              message = "${e.message}";
            } catch (e) {
              message = e.toString();
            }
            setState(() {
              printStatus = PrintStatus.ERROR;
            });
          });
          break;
        case btnPrintZplFileOverTCPIP:
          if (filePath != null && !pathController.text.endsWith(".zpl")) {
            throw Exception(
                "Make sure you properly write the path or selected a proper zpl file");
          }
          File zplFile = File(filePath!);
          if (await zplFile.exists()) {
            zplData = await zplFile.readAsString();
          }
          if (zplData == null || zplData!.isEmpty) {
            throw Exception(
                "Make sure you properly write the path or selected a proper zpl file");
          }
          setState(() {
            message = "Print job started...";
            printStatus = PrintStatus.PRINTING;
          });
          widget.zsdk
              .printZplDataOverTCPIP(
                  data: zplData!,
                  address: addressIpController.text,
                  port: int.tryParse(addressPortController.text),
                  printerConf: Printer.PrinterConf(
                    cmWidth: double.tryParse(widthController.text),
                    cmHeight: double.tryParse(heightController.text),
                    dpi: double.tryParse(dpiController.text),
                    orientation: printerOrientation,
                  ))
              .then((value) {
            setState(() {
              printStatus = PrintStatus.SUCCESS;
              message = "$value";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                message =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause}";
              } catch (e) {
                print(e);
                message = e.toString();
              }
            } on MissingPluginException catch (e) {
              message = "${e.message}";
            } catch (e) {
              message = e.toString();
            }
            setState(() {
              printStatus = PrintStatus.ERROR;
            });
          });
          break;

        case btnPrintZplDataOverTCPIP:
          zplData = zplDataController.text;
          if (zplData == null || zplData!.isEmpty) {
            throw Exception("ZPL data can't be empty");
          }
          setState(() {
            message = "Print job started...";
            printStatus = PrintStatus.PRINTING;
          });
          widget.zsdk
              .printZplDataOverTCPIP(
                  data: zplData!,
                  address: addressIpController.text,
                  port: int.tryParse(addressPortController.text),
                  printerConf: Printer.PrinterConf(
                    cmWidth: double.tryParse(widthController.text),
                    cmHeight: double.tryParse(heightController.text),
                    dpi: double.tryParse(dpiController.text),
                    orientation: printerOrientation,
                  ))
              .then((value) {
            setState(() {
              printStatus = PrintStatus.SUCCESS;
              message = "$value";
            });
          }, onError: (error, stacktrace) {
            try {
              throw error;
            } on PlatformException catch (e) {
              Printer.PrinterResponse printerResponse;
              try {
                printerResponse = Printer.PrinterResponse.fromMap(e.details);
                message =
                    "${printerResponse.message} ${printerResponse.errorCode} ${printerResponse.statusInfo.status} ${printerResponse.statusInfo.cause}";
              } catch (e) {
                print(e);
                message = e.toString();
              }
            } on MissingPluginException catch (e) {
              message = "${e.message}";
            } catch (e) {
              message = e.toString();
            }
            setState(() {
              printStatus = PrintStatus.ERROR;
            });
          });
          break;
      }
    } catch (e) {
      print(e);
      showSnackBar(e.toString());
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
