import 'package:flutter/material.dart';

class MyScaffold extends StatelessWidget{
  const MyScaffold ({super.key});
  @override
  Widget build(BuildContext context) {
    // Tra ve Scaffold - wiget
    return Scaffold(
      // Tieu de ung dung
      appBar: AppBar(
        title: Text("App 02"),
      ),


      body: Center(child:Text("Noi dung chinh"),),
        floatingActionButton: FloatingActionButton(onPressed: (){print("pressed");},
          child: const Icon(Icons.add_ic_call),
      ),
        bottomNavigationBar: BottomNavigationBar(items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chu"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Tim kiem"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Can Nhan"),

        ]),
    );
  }
}