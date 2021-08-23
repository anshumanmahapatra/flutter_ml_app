import 'dart:io';
import 'dart:ui';

import '../widgets/custom_rect_tween.dart';
import '../widgets/hero_page_route.dart';

import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:tflite/tflite.dart';

import 'package:flutter/material.dart';

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
            model: 'assets/tflite/model.tflite',
            labels: 'assets/tflite/labels.txt')
        .then((value) {
      debugPrint("The value after loading the model is : $value ");
      setState(() {
        loading = false;
      });
    });
  }

  Future classifyImage(File tempImage) async {
    try {
      List? result = await Tflite.runModelOnImage(
        path: tempImage.path,
        numResults: 36,
        threshold: 0.5,
        imageMean: 127.5,
        imageStd: 127.5,
      );

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
      final image = await ImagePicker()
          .pickImage(source: source)
          .whenComplete(() => Navigator.pop(context));
      if (image == null) return;

      final path = image.path;
      debugPrint("The path of image is: $path");

      setState(() {
        loading = true;
        this.image = File(path);
      });

      classifyImage(this.image!);
    } on Exception catch (e) {
      debugPrint('Failed to pick image: $e');
    }
  }

  Widget customButton() {
    return Align(
      alignment: const Alignment(0, 0.85),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Hero(
          tag: 'add-photo',
          createRectTween: (begin, end) {
            return CustomRectTween(begin: begin!, end: end!);
          },
          child: Material(
            color: Colors.blueGrey[600],
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            child: SizedBox(
              height: 150,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: <Widget>[
                  ListTile(
                    onTap: () {
                      pickImage(ImageSource.camera);
                    },
                    leading: const Icon(Icons.camera_alt_outlined,
                        color: Colors.white),
                    title: const Text("Camera",
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  ListTile(
                    onTap: () {
                      pickImage(ImageSource.gallery);
                    },
                    leading: const Icon(Icons.photo_library_outlined,
                        color: Colors.white),
                    title: const Text("Gallery",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                          ? SizedBox(
                              height: 250,
                              width: 250,
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(30),
                                  child: Image.file(
                                    image!,
                                    fit: BoxFit.contain,
                                  )))
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
                  Hero(
                    tag: 'add-photo',
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(HeroDialogRoute(
                            builder: (context) => customButton()));
                      },
                      child: const Text("Select an Image",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blueGrey[600],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                    ),
                  ),
                ])),
      ),
    );
  }
}
