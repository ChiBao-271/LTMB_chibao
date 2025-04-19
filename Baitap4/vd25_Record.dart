void main(){
  var r = ("first", a:2, 5, 10.5);

  var point = (123,456);

  // Định nghĩa person
  var person = (name: 'Alice', age: 25 , 5);


  // Truy cập giá trong Record
  // Dùng chỉ số
  print(point.$1);
  print(point.$2);
  print(person.$1);

  // 
  print(person.name);
    print(person.age);

}