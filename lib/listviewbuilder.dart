import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ListViewBuilder extends StatelessWidget{
  final Uint8List? receivedImage;
  const ListViewBuilder({super.key, this.receivedImage});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return ListView.builder(
      itemCount: 10, // Replace with your messages list length
      itemBuilder: (context, index) {
        return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  width: 300,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: receivedImage!.isNotEmpty
                      ? Image.memory(
                      receivedImage!, // Assuming imageData is a Uint8List
                      fit: BoxFit.fill
                  )
                      : Text("No Image"),
                )
            )
        );
      },
    );
  }

}