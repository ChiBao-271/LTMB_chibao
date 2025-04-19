import 'dart:io';


void main(){
  // Nhập tên người dùng
  stdout.write("Nhap vao ten cua ban: ");
  String name = stdin.readLineSync()!;

  // Nhập tuổi 
  stdout.write("Nhap vao tuoi cua ban: ");
  int age = int.parse(stdin.readLineSync()!);

  print("Xin chao: $name, tuoi cua ban la: $age");

}