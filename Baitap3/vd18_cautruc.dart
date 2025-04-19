import 'dart:async';
import 'dart:html_common';

void main(){
  // Định nghĩa: 
  // - list là 1 tập hợp có 



  List<String> list1 = ['A', 'B', 'C']; // Trực tiếp
  var list2 = [1,2,3];
  List<String> list3 = []; // List rỗng
  var list4 = List<int>.filled(3,0); // List có kích thước cố định
  print(list4);

 // 1. Thêm phần tử
  list1.add('D'); // cách thêm 1 phần tử
  // thêm nhiều phần tử
  list1.addAll(['A', 'C']); // Them 1 phan tu
  list1.insert(0, 'Z'); // chen` 1 phan tu
    list1.insertAll(1, ['1','0']); // chen nhieu ptu
  print(list1);

  // 2. Xóa phần tử bên trong List
  list1.remove('A'); // Xoa phan tu co gia tri trong (...);
  list1.removeAt(0); //Xoas phan tu tai vi tri (...);
  list1.removeLast; // Xoa vi tri cuoi
  list1.removeWhere((e)=>e=='B'); // Xoa theo dieu kien 
  list1.clear();  
  print(list1);

  // 3. Truy cập phần tử:
  print(list2[0]); // Lấy phần tử tại vị trí số [...] (trong ngoặc vuông) |
  print(list2.first); // lấy phần tử đầu tiên                             |
  print(list2.last); // Lấy phần tử cuối cùng                             |
  print(list2.length); // lấy độ dài                                      |

  // 4.  kiểm tra 
  print(list2.isEmpty); // Kiểm tra rỗng
  print('List 3: ${list3.isNotEmpty?'Không rỗng': 'rỗng'}');
  print(list4.contains('1')); // kiểm tra xem có chứa (..) hay khu
  print(list4.contains('0'));
  print(list4.indexOf(0));
  print(list4.lastIndexOf(0));

  // 5. Biến đổi
  list4 = [2, 1, 4, 3, 6, 8, 7, 5];
  print(list4); 
  list4.sort(); // Sắp xếp tăng dần
  print(list4); 
  list4.reversed; // Đảo ngược
  print(list4.reversed); 
  //cach 2
  list4 = list4.reversed.toList();
  print(list4); 

  // Cắt và nối
  var subList = list4.sublist(1,3); // cắt 1 sublist từ 1 đến < 3;
  print(subList);

  var str_Joined = list4.join(',');
  print(str_Joined);


  //8. Duyệt các phần tử bên trong List
  list4.forEach((element){
    print(element);
  });
  //
  

  }





