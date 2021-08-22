import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool loading = false;
  List? output;
  File? image;

  @override
  void initState() {
    super.initState();
    loading = true;
    loadModel();
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
  }

  Future loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
            model: 'assets/tflite/tf_lite_model.tflite',
            labels: 'assets/tflite/labels.txt')
        .then((value) {
      debugPrint("The value after loading the model successfully is : $value ");
      setState(() {
        loading = false;
      });
    });
  }

  Future classifyImage(File image) async {
    try {
      List? result = await Tflite.runModelOnImage(
          path: image.path,
          numResults: 10,
          threshold: 0.5,
          imageMean: 127.5,
          imageStd: 127.5);

      debugPrint(
          "This shows that the model is working fine but we have some error in UI. The result obtained is : ${result![0]['label']}");

      setState(() {
        loading = false;
        output = result;
      });
    } on Exception catch (e) {
      debugPrint(" The error while classifying image is: ${e.toString()}");
    }
  }

  Future pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null) return;

      final path = image.path;

      final croppedImage = await ImageCropper.cropImage(
          sourcePath: path,
          aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
          aspectRatioPresets: [CropAspectRatioPreset.square],
          maxHeight: 28,
          maxWidth: 28);

      debugPrint("Image successfully cropped");

      setState(() {
        loading = true;
        this.image = croppedImage;
      });

      var decodedImage =
          await decodeImageFromList(this.image!.readAsBytesSync());
      debugPrint("Decode image width: ${decodedImage.width}");
      debugPrint("Decode image height: ${decodedImage.height}");
      debugPrint("Now called the classifyImage function");
      classifyImage(this.image!);
    } on Exception catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter ML App"),
        centerTitle: true,
        elevation: 0.0,
        backgroundColor: Colors.black,
      ),
      body: Container(
        height: size.height,
        width: size.width,
        color: Colors.black87,
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 35),
        child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A363B),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  loading == true
                      ? Lottie.asset("assets/lottie/loading.json")
                      : output != null
                          ? Image.file(image!)
                          : Lottie.asset("assets/lottie/hello.json"),
                  const SizedBox(
                    height: 40,
                  ),
                  Text(
                      loading == true
                          ? "Please wait till we load the model"
                          : output != null
                              ? 'The object is: ${output![0]['label']}!'
                              : "Select an Image to predict",
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                      onPressed: () {
                        pickImage(ImageSource.camera);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      icon: const Icon(Icons.camera_alt_outlined,
                          color: Colors.white),
                      label: const Text("Camera",
                          style: TextStyle(color: Colors.white))),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton.icon(
                      onPressed: () {
                        pickImage(ImageSource.gallery);
                      },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                      icon: const Icon(Icons.image, color: Colors.white),
                      label: const Text("Gallery",
                          style: TextStyle(color: Colors.white))),
                ])),
      ),
    );
  }
}
