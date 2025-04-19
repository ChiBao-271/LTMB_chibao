void main(){
  var s1='Pham la Chi bao';
  var s2 ="Kien cang";

  // chèn giá trị của một biểu thức, biến vào trong chuỗi: $(...)
    double diemToan=9.5;
    double diemVam=8.6;
    print('xin chào $s1, bạn đã đạt tổng điểm là : ${diemToan+diemVam}');


  // tạp ra chuỗi kí tự ở nhiều dòng
// Ví dụ đúng bài học =))))
   var s6 = '''
              Kiểu 1
              Kiểu 2
              kiểu 3
            ''';
    print(s6);

// ví dụ dài dòng, phiền, mất thời gian =)))))
  var s8="Chuỗi 1" + " Chuỗi 2";
  print (s8); // mất thười gian bấm dấu + :D?


  var s9="Chuỗi"
          " này"
          'là'
          'một'
          "chuỗi";
        print(s9); // mất thời gian xuống dòng, bấm dấu nháy xong còn sai :D?
}