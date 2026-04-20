import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import '../model/clinic_model.dart';
import '../model/prescription_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:dio/dio.dart';
import '../model/prescription_pre_field_model.dart';
import '../utilities/colors_constant.dart';
import '../widget/loading_Indicator_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:flutter_drawing_board/paint_contents.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controller/prescription_controller.dart';
import '../helper/custom_drawn_helper.dart';
import '../helper/image_drawn_helper.dart';
import '../helper/pre_field_text_prescription.dart';
import '../utilities/api_content.dart';
import '../widget/toast_message.dart';
import 'package:get/get.dart' as getX;
import '../service/clinic_service.dart';

class WritePrescriptionPage extends StatefulWidget {
    final PrescriptionPreFieldModel? prescriptionPreFieldModel;
    final PrescriptionModel? prescriptionModel;

  const WritePrescriptionPage({super.key,
      this.prescriptionModel,
    this.prescriptionPreFieldModel,
  });

  @override
  State<WritePrescriptionPage> createState() => _WritePrescriptionPageState();
}

class _WritePrescriptionPageState extends State<WritePrescriptionPage> {
   List<DrawingController> _drawingControllers = [DrawingController()];
  int _currentPageIndex = 0;
  // final DrawingController _drawingController = DrawingController();
  final TransformationController _transformationController = TransformationController();
  PrescriptionController prescriptionController=getX.Get.find<PrescriptionController>();
  double _colorOpacity = 1;
  final List<List<Offset>> pages = [<Offset>[]];
  List<PaintContent?> drawnObjects = [];
  PaintContent? selectedObject;
  Offset? _dragStartOffset;
  ClinicModel? clinicModel;
  ui.Image? logoImage;
  bool _isLoading = false;
  bool uploadFileLoading = false;
  bool _isLoadingImg = false;
  PrescriptionPreFieldModel? prescriptionPreFieldModel;
  List<Uint8List?> _pageImages = [];
  @override
  void initState() {
    // TODO: implement initState
    getAndSetData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerDrawingBoard();
    });
    super.initState();
  }

  @override
  void dispose() {
    for (var controller in _drawingControllers) {
      controller.dispose();
    }
    super.dispose();
  }



   Future<void> uploadPdfAndJson() async {
    setState(() {
      uploadFileLoading = true;
    });
    try {
      _pageImages[_currentPageIndex] = (await _drawingControllers[_currentPageIndex].getImageData())?.buffer.asUint8List();
      final pdf = pw.Document();
      // final List<Map<String, dynamic>> allPageJsonData = [];
        if (kDebugMode) {
          print("Drawing Length is ${_drawingControllers.length}");
        }
      // Iterate through all drawing controllers to capture each page
      for (int i=0;i<_drawingControllers.length;i++) {
        final Uint8List? imageData = ( _pageImages[i]);
     //   final List<dynamic> jsonList = _drawingControllers[i].getJsonList();
      //  print("Page Image Length is ${_pageImages.length}");
      //  print("Page Image Data ${_pageImages[i]}");
        if (imageData == null
           // || jsonList.isEmpty
        ) {
          debugPrint("Skipping page: Missing data (PDF or JSON). $i  image data $imageData");
          continue;
        }
        // allPageJsonData.add({
        //   "page": i,
        //   "jsonData": jsonList,
        // });
// Collect JSON data from all pages
        print("Adding image in pdf --$i");
        // Add a new page to the PDF
        pdf.addPage(
          pw.Page(
            margin: pw.EdgeInsets.zero, // Removes all margins
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(
                  pw.MemoryImage(imageData),
                  fit: pw.BoxFit.contain, // Ensures the drawing is fully visible
                ),
              );
            },
          ),
        );

      }

      // if (pdf.pages.isEmpty) {
      //   debugPrint("No valid pages to save. Aborting upload.");
      //   setState(() {
      //     uploadFileLoading = false;
      //   });
      //   return;
      // }

      // 📂 Save PDF locally
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/prescription.pdf';
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // ✅ Debug PDF File Creation
      if (await file.exists()) {
        debugPrint("PDF Created Successfully: ${file.path}");
       // await OpenFile.open(filePath);
      } else {
        debugPrint("PDF Creation Failed.");
        return;
      }

      // 📝 Convert JSON data to a string
      // String jsonString = jsonEncode(allPageJsonData);
      // debugPrint("JSON Data Sent: $jsonString"); // ✅ Debug JSON Data

      // 🔑 Get Token from SharedPreferences
      Dio dio = Dio();
      SharedPreferences preferences = await SharedPreferences.getInstance();
      final token = preferences.getString('token') ?? "";
      dio.options.headers["authorization"] = "Bearer $token";

      // 📤 Prepare Dio Multipart Request
      FormData formData = FormData.fromMap({
        "pdf_file": await MultipartFile.fromFile(file.path, filename: "prescription.pdf"),
      //  "json_data": jsonString,
        "appointment_id": widget.prescriptionPreFieldModel?.appointmentID.toString(),
        "patient_id": widget.prescriptionPreFieldModel?.patientId.toString(),
      });

      // 🚀 Send Request
      Response response = await dio.post(
        ApiContents.uploadPrescriptionUrl,
        data: formData,
        options: Options(),
      );

      // 📡 Handle Response
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.toString());
        debugPrint("Response: $jsonData");

        if (jsonData['response'] == 201) {
          if (jsonData['status'] == "error") {
            IToastMsg.showMessage("Something went wrong");
          } else {
            IToastMsg.showMessage(jsonData['message']);
          }
        } else if (jsonData['response'] == 200) {
          getX.Get.back();
          prescriptionController.getData(
            appointmentId: widget.prescriptionPreFieldModel?.appointmentID.toString() ?? "",
          );
          IToastMsg.showMessage("Successfully Uploaded");
          final file = jsonData['file'];
          launchUrl(Uri.parse("${ApiContents.imageUrl}/$file"));
        }
      } else {
        debugPrint("Upload Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("⚠️ Error Uploading Data: $e");
    }

    setState(() {
      uploadFileLoading = false;
    });
  }






  void _selectObject(Offset tapPosition) {
    setState(() {
      selectedObject = drawnObjects.lastWhere(
            (object) => object!.isNear(tapPosition),
        orElse: () => null,
      );
    });
  }

  void _moveObject(Offset delta) {
    if (selectedObject != null) {
      setState(() {
        selectedObject!.move(delta);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop:!uploadFileLoading ,

      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        appBar:uploadFileLoading||_isLoading?null: AppBar(
          leading: PopupMenuButton<Color>(
            icon: const Icon(Icons.color_lens),
            onSelected: (Color value) =>
                _drawingControllers[_currentPageIndex].setStyle(
                  color: value.withOpacity(_colorOpacity),
                ),
            itemBuilder: (_) {
              return <PopupMenuEntry<Color>>[
                PopupMenuItem<Color>(
                  child: StatefulBuilder(
                    builder: (BuildContext context,
                        Function(void Function()) setState) {
                      return Slider(
                        value: _colorOpacity,
                        onChanged: (double v) {
                          setState(() => _colorOpacity = v);
                          _drawingControllers[_currentPageIndex].setStyle(
                            color: _drawingControllers[_currentPageIndex].drawConfig.value.color
                                .withOpacity(_colorOpacity),
                          );
                        },
                      );
                    },
                  ),
                ),
                PopupMenuItem<Color>(
                    value: Colors.black,
                    child: Container(width: 100, height: 50, color: Colors.black),
                    ),
                ...Colors.accents.map((Color color) {
                  return PopupMenuItem<Color>(
                    value: color,
                    child: Container(width: 100, height: 50, color: color),
                  );
                }),
              ];
            },
          ),
          title:  Text('write_prescription'.tr),
          systemOverlayStyle: SystemUiOverlayStyle.light,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.save,
              color: ColorResources.btnColor,),
              onPressed: _openDialogBoxToSave
            ),
          ],
        ),
        body:uploadFileLoading|| _isLoading?ILoadingIndicatorWidget():
        Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  _selectObject(details.localPosition);
                },
                onPanStart: (details) {
                  if (selectedObject != null) {
                    _dragStartOffset = details.localPosition;
                  }
                },
                onPanUpdate: (details) {
                  if (selectedObject != null && _dragStartOffset != null) {
                    final delta = details.localPosition - _dragStartOffset!;
                    _moveObject(delta);
                    _dragStartOffset = details.localPosition;
                  }
                },
                onPanEnd: (details) {
                  _dragStartOffset = null;
                },
                child: LayoutBuilder(
                  key: ValueKey<int>(_currentPageIndex),
                  builder: (BuildContext context, BoxConstraints constraints) {
                    return Container(
                      color: Colors.grey.shade100,
                      child: DrawingBoard(
                        transformationController: _transformationController,
                        controller: _drawingControllers[_currentPageIndex],
                        background: !_isLoadingImg?Container(
                          color: Colors.white,
                          child: CustomPaint(
                            size: Size(595.28,841.89),
                            painter: PreFilledTextPainter(logoImage,prescriptionPreFieldModel), // Paints the pre-filled text
                          ),
                        ):Container(),
                        showDefaultActions: true,
                        showDefaultTools: true,
                        defaultToolsBuilder: (Type t, _) {
                          List<DefToolItem> tools = DrawingBoard.defaultTools(t, _drawingControllers[_currentPageIndex],);

                          // Find the Eraser tool and remove it from its original position
                          DefToolItem? eraserTool = tools.firstWhere(
                                (tool) => tool.icon == CupertinoIcons.bandage,
                            orElse: () => DefToolItem( // Provide a default Eraser tool if not found
                              icon: CupertinoIcons.bandage,
                              isActive: t == Eraser,
                              onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(Eraser()),
                            ),
                          );


                            tools.remove(eraserTool);


                          DefToolItem? circleTool = tools.firstWhere(
                                (tool) => tool.icon == CupertinoIcons.circle,
                            orElse: () => DefToolItem( // Provide a default Eraser tool if not found
                              icon: CupertinoIcons.circle,
                              isActive: t == Circle,
                              onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(Circle()),
                            ),
                          );
                            tools.remove(circleTool);
                          DefToolItem? rectangleTool =  tools.firstWhere(
                                (tool) => tool.icon == CupertinoIcons.stop,
                            orElse: () => DefToolItem( // Provide a default Eraser tool if not found
                              icon: CupertinoIcons.stop,
                              isActive: t == Rectangle,
                              onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(Rectangle()),
                            ),
                          );
                          tools.remove(rectangleTool);


                          return tools
                            ..insert(
                              2,
                                DefToolItem(
                                icon: CupertinoIcons.bandage,
                                isActive: t == Eraser,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(Eraser()),
                              ),
                            )
                            ..insert(
                              3,
                              DefToolItem(
                                icon: Icons.compare_arrows_outlined,
                                isActive: t == FrontArrow,
                                onTap: () =>
                                _drawingControllers[_currentPageIndex].setPaintContent(
                                        FrontArrow()),
                              ),
                            )..insert(
                              4,
                              DefToolItem(
                                icon: Icons.compress,
                                isActive: t == BackArrow,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(
                                    BackArrow()),
                              ),
                            )
                            ..insert(
                              5,
                              DefToolItem(
                                icon: Icons.rectangle_outlined,
                                isActive: t == BackArrow,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(
                                    Rectangle()),
                              ),
                            )
                            ..insert(6,
                               DefToolItem(
                                icon: CupertinoIcons.circle,
                                isActive: t == Eraser,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(Circle()),
                              ),
                            )
                            ..insert(
                              7,
                              DefToolItem(
                                icon: (Icons.circle),
                                isActive: t == Ellipse,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(
                                    Ellipse()),
                              ),
                            )..insert(
                              8,
                              DefToolItem(
                                icon: Icons.change_history_rounded,
                                isActive: t == Triangle,
                                onTap: () => _drawingControllers[_currentPageIndex].setPaintContent(
                                    Triangle()),
                              ),
                            )
                        ..insert(
                          9,
                          DefToolItem(
                          icon: Icons.star,
                          isActive: t == Star,
                          onTap: () =>
                          _drawingControllers[_currentPageIndex].setPaintContent(Star()),
                          ),
                          )
                            ..insert(
                              10,
                              DefToolItem(
                                icon: Icons.image_rounded,
                                isActive: t == ImageContent,
                                onTap: () async {
                                  final ImagePicker picker = ImagePicker();

                                  // Show a loading dialog
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    },
                                  );
                                  try {
                                    // Pick image from gallery
                                    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

                                    if (imageFile != null && context.mounted) {
                                      final File file = File(imageFile.path);
                                      final Uint8List bytes = await file.readAsBytes();

                                      // Convert file bytes to a dart:ui Image
                                      final ui.Image image = await decodeImageFromList(bytes);
                                      _drawingControllers[_currentPageIndex].setPaintContent(
                                        ImageContent(image, imageUrl: imageFile.path), // Pass correct Image type
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to load image: $e')),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                    }
                                  }
                                },
                              ),
                            );

                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _currentPageIndex > 0 ? () => _changePage(_currentPageIndex - 1) : null,
                    ),
                    Text("page_value".trParams({"value_1":"${_currentPageIndex + 1}","value_2":"${_drawingControllers.length}"})),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: _currentPageIndex < _drawingControllers.length - 1
                          ? () => _changePage(_currentPageIndex + 1)
                          : null,
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _addNewPage,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: ColorResources.greenFontColor,
                        child:  Icon(Icons.add,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  _drawingControllers.length>1?  GestureDetector(
                      onTap: _openDialogBox,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: ColorResources.btnColorRed,
                        child:  Icon(Icons.remove,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ):Container(),   const SizedBox(width: 10),

                  ],
                )



              ],
            ),
          ],
        ),
      ),
    );
  }
  void _addNewPage() async{
    setState(() {
      _isLoading=true;
    });
    _pageImages[_currentPageIndex] = (await _drawingControllers[_currentPageIndex].getImageData())?.buffer.asUint8List();

    _drawingControllers.add(DrawingController());
    _currentPageIndex = _drawingControllers.length - 1; // Set to last page
    final newPageImage=(await _drawingControllers[_currentPageIndex].getImageData())?.buffer.asUint8List();
    _drawingControllers[_currentPageIndex].setStyle(color: Colors.black);

    _pageImages.add(newPageImage);

    setState(() {
      _isLoading=false;
    });
  }
  // // Function to switch pages
  // void _changePage(int index) {
  //   if (index >= 0 && index < _drawingControllers.length) {
  //     setState(() {
  //       _currentPageIndex = index;
  //     });
  //   }
  // }
  void _changePage(int index) async {
    setState(() {
      _isLoading=true;
    });
    // print("Length ------------${_pageImages.length}");
    if (index < 0 || index >= _drawingControllers.length || index == _currentPageIndex) return;

    // Save current page's image data before switching
    _pageImages[_currentPageIndex] = (await _drawingControllers[_currentPageIndex].getImageData())?.buffer.asUint8List();

    setState(() {
      _currentPageIndex = index;
    });

    // Debugging logs
    debugPrint("Switched to Page: $_currentPageIndex");
    debugPrint("Stored Image Data for Page $_currentPageIndex: ${_pageImages[_currentPageIndex] != null}");
    setState(() {
      _isLoading=false;
    });
  }


  void getAndSetData() async {
    setState(() {
      _isLoading=true;
    });
    final newPageImage=(await _drawingControllers[0].getImageData())?.buffer.asUint8List();
    _pageImages.add(newPageImage);
    clinicModel = await ClinicService.getDataById(clinicId:widget.prescriptionPreFieldModel?.clinicId);
    if(clinicModel?.image!=null&&clinicModel?.image!=""){
      _loadNetworkImage("${ApiContents.imageUrl}/${clinicModel?.image}");

    }
    prescriptionPreFieldModel = PrescriptionPreFieldModel(
      appointmentID: widget.prescriptionPreFieldModel?.appointmentID,
      patientId: widget.prescriptionPreFieldModel?.patientId,
      patientName: widget.prescriptionPreFieldModel?.patientName,
      patientAge: widget.prescriptionPreFieldModel?.patientAge,
      patientGender: widget.prescriptionPreFieldModel?.patientGender,
      patientPhone: widget.prescriptionPreFieldModel?.patientPhone,
      doctorName: widget.prescriptionPreFieldModel?.doctorName,
      doctorSpec: widget.prescriptionPreFieldModel?.doctorSpec,
      doctorDept: widget.prescriptionPreFieldModel?.doctorDept,
      clinicAddress:clinicModel?.address??"",
      clinicName: clinicModel?.title??"",
      phone:"${clinicModel?.phone},${clinicModel?.phoneSecond}" ,
        email: clinicModel?.email,
    );
    _drawingControllers[0].setStyle(color: Colors.black);

    setState(() {
      _isLoading=false;
    });
  }
  Future<void> _loadNetworkImage(String imageUrlFinal) async {

    setState(() {
      _isLoadingImg=true;
    });
    final String imageUrl = imageUrlFinal; // Replace with your actual image URL
    final Dio dio = Dio();

    try {
      final Response<Uint8List> response = await dio.get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final img.Image? image = img.decodeImage(response.data!);

      if (image != null) {
        final ui.Codec codec = await ui.instantiateImageCodec(Uint8List.fromList(img.encodePng(image)));
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        setState(() {
          logoImage = frameInfo.image;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Failed to load image: $e");
      }
    }
    if(mounted){
      setState(() {
        _isLoadingImg=false;
      });
    }


  }
  Future<dynamic> _openDialogBox() {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title:  Text(
            "delete_page".tr,
            textAlign:  TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          content:  Column(
            mainAxisSize: MainAxisSize.min,
            children:  [
              Text("delete_the_current_page".trParams({"value":"${_currentPageIndex+1}"}),
                  style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
              const  SizedBox(height: 10),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorRed,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                  ),
                ),
                child:  Text("no".tr,
                    style:
                    TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w400, fontSize: 12)),
                onPressed: () {
                  Navigator.of(context).pop();
                }),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorResources.btnColorGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                  ),
                ),
                onPressed:(){
                  Navigator.of(context).pop();
              _deleteCurrentPage();
                } ,
                child:  Text(
                  "yes".tr,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w400, fontSize: 12),
                )),
            // usually buttons at the bottom of the dialog
          ],
        );
      },
    );
  }
   Future<dynamic> _openDialogBoxToSave() {
     return showDialog(
       context: context,
       builder: (BuildContext context) {
         // return object of type Dialog
         return AlertDialog(
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(20.0),
           ),
           title:  Text(
             "confirmation".tr,
             textAlign:  TextAlign.center,
             style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
           ),
           content:  Column(
             mainAxisSize: MainAxisSize.min,
             children:  [
               Text("upload_pages_prescription_desc".tr,
                   style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14)),
               const  SizedBox(height: 10),
             ],
           ),
           actions: <Widget>[
             ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: ColorResources.btnColorRed,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                   ),
                 ),
                 child:  Text("no".tr,
                     style:
                     TextStyle(
                         color: Colors.white,
                         fontWeight: FontWeight.w400, fontSize: 12)),
                 onPressed: () {
                   Navigator.of(context).pop();
                 }),
             ElevatedButton(
                 style: ElevatedButton.styleFrom(
                   backgroundColor: ColorResources.btnColorGreen,
                   shape: RoundedRectangleBorder(
                     borderRadius: BorderRadius.circular(10), // Change this value to adjust the border radius
                   ),
                 ),
                 onPressed:(){
                   Navigator.of(context).pop();
                   uploadPdfAndJson();
                 } ,
                 child:  Text(
                   "yes".tr,
                   style: TextStyle(
                       color: Colors.white,
                       fontWeight: FontWeight.w400, fontSize: 12),
                 )),
             // usually buttons at the bottom of the dialog
           ],
         );
       },
     );
   }
  void _deleteCurrentPage() {

    if (_drawingControllers.length > 1) {
      setState(() {
        // Remove the current drawing controller
        _drawingControllers.removeAt(_currentPageIndex);

        // Shift remaining pages to maintain correct indexing
        List<DrawingController> updatedControllers = [];
        for (int i = 0; i < _drawingControllers.length; i++) {
          updatedControllers.add(_drawingControllers[i]); // Reassign controllers in order
        }
        _drawingControllers = updatedControllers;

        List<Uint8List?> updatedPageImage = [];
        for (int i = 0; i < _pageImages.length; i++) {
          updatedPageImage.add(_pageImages[i]); // Reassign controllers in order
        }
        _pageImages=updatedPageImage;

        // Adjust current index safely
        if (_currentPageIndex >= _drawingControllers.length) {
          _currentPageIndex = _drawingControllers.length - 1;
        } else {
          _currentPageIndex = 0; // Reset to first page after deletion
        }
      });
      setState(() {

      });

      debugPrint("Page deleted. Remaining Pages: ${_drawingControllers.length}");
    } else {
      debugPrint("Cannot delete the last remaining page.");
    }
  }
   void _centerDrawingBoard() {
     final Size screenSize = MediaQuery.of(context).size;
     final double drawingBoardWidth = 595.28; // A4 width in points
     final double drawingBoardHeight = 841.89; // A4 height in points

     final double scaleX = screenSize.width / drawingBoardWidth;
     final double scaleY = screenSize.height / drawingBoardHeight;
     final double scale = min(scaleX, scaleY);

     final double offsetX = (screenSize.width - drawingBoardWidth * scale) / 2;
     final double offsetY = (screenSize.height - drawingBoardHeight * scale) / 2;

     _transformationController.value = Matrix4.identity()
       ..translate(offsetX, offsetY)
       ..scale(scale);
   }
}

// Add a `move` method to `PaintContent` to enable object movement
extension PaintContentExtension on PaintContent {
  void move(Offset delta) {
    if (this is ImageContent) {
      final imageContent = this as ImageContent;
      imageContent.startPoint += delta;
    } else if (this is Star) {
      final star = this as Star;
      star.startPoint += delta;
      star.points = star.points.map((point) => point + delta).toList();
    } else if (this is Ellipse) {
      final ellipse = this as Ellipse;
      ellipse.startPoint += delta;
      ellipse.endPoint += delta;
    } else if (this is Arrow) {
      final arrow = this as Arrow;
      arrow.startPoint += delta;
      arrow.endPoint += delta;
    } else if (this is Triangle) {
      final triangle = this as Triangle;
      triangle.startPoint += delta;
      triangle.A += delta;
      triangle.B += delta;
      triangle.C += delta;
    }
  }

  bool isNear(Offset point) {
    if (this is ImageContent) {
      final imageContent = this as ImageContent;
      final rect = Rect.fromPoints(imageContent.startPoint, imageContent.startPoint + imageContent.size);
      return rect.contains(point);
    } else if (this is Star) {
      final star = this as Star;
      return star.points.any((p) => (p - point).distance < 10);
    } else if (this is Ellipse) {
      final ellipse = this as Ellipse;
      final rect = Rect.fromPoints(ellipse.startPoint, ellipse.endPoint);
      return rect.contains(point);
    } else if (this is Arrow) {
      final arrow = this as Arrow;
      final path = Path()
        ..moveTo(arrow.startPoint.dx, arrow.startPoint.dy)
        ..lineTo(arrow.endPoint.dx, arrow.endPoint.dy);
      return path.contains(point);
    } else if (this is Triangle) {
      final triangle = this as Triangle;
      final path = Path()
        ..moveTo(triangle.A.dx, triangle.A.dy)
        ..lineTo(triangle.B.dx, triangle.B.dy)
        ..lineTo(triangle.C.dx, triangle.C.dy)
        ..close();
      return path.contains(point);
    }
    return false;
  }

}
