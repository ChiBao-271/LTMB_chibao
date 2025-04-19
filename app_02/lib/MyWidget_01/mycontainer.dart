import 'package:flutter/material.dart';

class mycontainer extends StatelessWidget{
  const mycontainer ({super.key});
  @override
  Widget build(BuildContext context) {
    // Tra ve Scaffold - wiget
    return SafeArea(child: Scaffold(
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
      body: Center(child: Container(
        width: 200,
        height: 200,
        padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),

          decoration: BoxDecoration(color: Colors.lightBlueAccent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
          ),
          ]

          ),
        child: Align(
          alignment: Alignment.center,
          child: const Text("Le Nhat Tung",
            style: TextStyle(color: Colors.pinkAccent, fontSize: 20),
          ),

        )
      ),),
      floatingActionButton: FloatingActionButton(onPressed: (){print("pressed");},
        child: const Icon(Icons.add_ic_call),
      ),
      bottomNavigationBar: BottomNavigationBar(items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chu"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Tim kiem"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Can Nhan"),

      ]),
    ),
    );
  }
}