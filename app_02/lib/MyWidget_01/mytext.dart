import 'package:flutter/material.dart';

class mytext extends StatelessWidget{
  const mytext ({super.key});
  @override
  Widget build(BuildContext context) {
    // Tra ve Scaffold - wiget
    return Scaffold(
      // Tieu de ung dung
      appBar: AppBar(
        // tieude
        title: Text("App 02"),
        backgroundColor: Colors.blue,

        elevation: 4,
        actions: [
          IconButton(onPressed: (){print("b1");},
              icon: Icon(Icons.search)),

          IconButton(onPressed: (){print("b2");},
              icon: Icon(Icons.abc)),


          IconButton(onPressed: (){print("b3");},
              icon: Icon(Icons.more_vert)),
        ],
      ),
      body: Center(child: Column(
        children: [
          //
          const SizedBox(height: 50,),
          //
          const Text("Le Nhat Tung"),
          const SizedBox(height: 20,),

          const Text(
            "Xin chao ca nha",
            textAlign:  TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20,),
          const Text(
            "Xin chao ca nha, Xin chao ca nha , Xin chao ca nha ,Xin chao ca nha",
            textAlign:  TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              color: Colors.black,
              letterSpacing: 1.5,
            ),
          )
        ],
      ),),
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