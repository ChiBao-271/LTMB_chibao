void main(){
  // int: là kiểu số nguyên
  int x= 100;
  // Double: là kiểu số thực
  double y=100.5;

  //Num: là kiểu dữ liệu có thể chứa số nguyên, cũng có thể là số thực
  num z = 10; 
  num t = 100.5; 

  //chuyển chuỗi sang số nguyên
  var one  = int .parse("1");
  print (one == 1?"true":"false");

  //Chuyển chuỗi sang số thức
   var onePointone = double.parse('1.1');
   print(onePointone==1.1);

   // số nguyên => chuỗi
   var onetoString = 3.13159.toStringAsFixed(2);
}