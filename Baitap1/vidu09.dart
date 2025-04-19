void main(){
  Object obj = 'Hello';

  // Kiem tra xem co phai la String?
if(obj is String){
  print('obj la mot String');
}
// Kiem tra k phai kieu int 
if(obj is! int){
  print('khong phai la so nguyen int');
}

// ep kieu
String str = obj as String;
print(str.toUpperCase());
}