/* Vidu1
 expr1 ? expr2 : expr3;
Nếu expr1 đúng sẽ trả về expr2, ngược lại sẽ trả về expr3

Vidu2
expr1 ?? expr2
neu expr1 khong null se tra ve gia tri cua no (expr1)
nguoc lai se tra lai expr2

*/
// Vidu 1:
void main(){
  var kiemTra = (100%2==0)?"100 la so chan": "100 la so le";
  print(kiemTra);

// Vidu 2:
  var x = 100;
  var y = x ?? 50;
  print(y);

  int? z;
  y = z ?? 30;
  print(y);
}