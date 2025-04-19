import "dart:async";
 
/*
Future là gì?
 
Hãy tưởng tượng bạn gọi món ăn tại một nhà hàng:
+ Bạn đặt món (gọi một hàm)
+ Nhân viên phục vụ nói "vâng, tôi sẽ mang món ăn đến sau" (nhận về một Future)
+ Bạn có thể làm việc khác trong lúc chờ đợi (tiếp tục chạy code)
Khi món ăn được phục vụ (Future hoàn thành), bạn có thể thưởng thức nó (sử dụng kết quả)
 
Future trong Dart cũng hoạt động tương tự.
Đó là một cách để làm việc với các tác vụ
mất thời gian mà không phải chờ đợi (ví dụ: tải dữ liệu từ internet, đọc tệp).
 
Hiểu rõ về "async/await"
async và await là hai từ khóa đặc biệt trong Dart giúp làm việc với Future dễ dàng hơn.
 
Từ khóa async:
- Khi thêm từ khóa async vào một hàm,
bạn đang nói với Dart: "Hàm này sẽ chứa code bất đồng bộ"
 
- Một hàm được đánh dấu async sẽ luôn luôn trả
về một Future (ngay cả khi bạn không khai báo nó)
 
*/
 
Future<String> layTen() async {
  return "Nguyen Van A";
}
 
/*
Từ khóa await
- await chỉ có thể được sử dụng bên trong một hàm async
Khi bạn đặt await trước một Future, Dart sẽ:
- Tạm dừng thực thi hàm tại dòng đó
- Đợi Future hoàn thành
- Trả về giá trị từ Future (không còn đóng gói trong Future nữa)
- Tiếp tục thực thi những dòng code còn lại
 
await biến đổi Future<T> thành giá trị T, giúp code dễ đọc hơn
 
*/
 
// Ham tra ve Future
Future<String> taiDuLieu() {
  return Future.delayed(Duration(seconds: 2), () => "Dữ liệu đã tải xong");
}
 
// Gọi hàm cách 1
void hamChinh1() {
  print("Bắt đầu tải");
  Future<String> f = taiDuLieu();
  f.then((ketQua) {
    print("Kết quả: $ketQua");
  });
  print("Tiếp tục công việc khác.");
}
 
// Gọi hàm cách 2
void hamChinh2() async {
  print("Bắt đầu tải"); // 1
  String ketQua = await taiDuLieu();
  print("Kết quả: $ketQua"); //2
  print("Tiếp tục công việc khác."); // 3
}
 
void main() {
  hamChinh2();
}