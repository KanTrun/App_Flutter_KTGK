# 🎤 HƯỚNG DẪN KIỂM TRA VOICE CONTROL CHO BÁOTHỨC

## 📱 **Bước 1: Khởi động ứng dụng**
- Mở ứng dụng trên điện thoại Android
- Vào màn hình "Đồng hồ báo thức"

## 🔊 **Bước 2: Kiểm tra quyền Microphone**
- Ứng dụng sẽ tự động xin quyền microphone
- Chấp nhận quyền để tiếp tục

## 🎯 **Bước 3: Test Voice Commands**

### ✅ **Test Case 1: Đặt báo thức cơ bản**
1. Nhấn nút "Bấm và nói" 🎤
2. Nói: **"Đặt báo thức 7 giờ 30 phút"**
3. **Kết quả mong đợi**: Báo thức được đặt lúc 07:30

### ✅ **Test Case 2: Đặt báo thức với giờ rưỡi**
1. Nhấn nút "Bấm và nói" 🎤
2. Nói: **"Báo thức 8 giờ rưỡi"**
3. **Kết quả mong đợi**: Báo thức được đặt lúc 08:30

### ✅ **Test Case 3: Đặt báo thức với thời gian trong ngày**
1. Nhấn nút "Bấm và nói" 🎤
2. Nói: **"Đặt báo thức 6 giờ sáng"**
3. **Kết quả mong đợi**: Báo thức được đặt lúc 06:00

### ✅ **Test Case 4: Đặt báo thức với số tiếng Việt**
1. Nhấn nút "Bấm và nói" 🎤
2. Nói: **"Báo thức bảy giờ ba mười phút"**
3. **Kết quả mong đợi**: Báo thức được đặt lúc 07:30

### ✅ **Test Case 5: Đặt báo thức định dạng số**
1. Nhấn nút "Bấm và nói" 🎤
2. Nói: **"Đặt giờ 9:15"**
3. **Kết quả mong đợi**: Báo thức được đặt lúc 09:15

### ✅ **Test Case 6: Hủy báo thức**
1. Sau khi đã đặt báo thức
2. Nhấn nút "Bấm và nói" 🎤
3. Nói: **"Hủy báo thức"**
4. **Kết quả mong đợi**: Báo thức bị hủy

### ✅ **Test Case 7: Tắt báo thức đang reo**
1. Khi báo thức đang reo
2. Nhấn nút "Bấm và nói" 🎤
3. Nói: **"Tắt báo thức"**
4. **Kết quả mong đợi**: Âm thanh báo thức dừng

## 🔍 **Kiểm tra UI/UX**
- ✅ Nút microphone đổi màu khi đang nghe (đỏ)
- ✅ Hiển thị "Đang nghe..." khi active
- ✅ Feedback message hiển thị lệnh đã nhận diện
- ✅ Thông báo kết quả hành động (đã đặt/hủy báo thức)
- ✅ Hướng dẫn sử dụng rõ ràng

## ❗ **Các lỗi có thể gặp**
- **"Microphone không khả dụng"**: Chưa cấp quyền hoặc thiết bị không hỗ trợ
- **"Không hiểu thời gian"**: Nói không rõ hoặc format không được hỗ trợ
- **"Không có báo thức nào để hủy"**: Chưa đặt báo thức trước đó

## 🎯 **Tiêu chí Pass/Fail**
- ✅ **PASS**: Voice command được nhận diện chính xác và thực hiện đúng hành động
- ❌ **FAIL**: Không nhận diện được hoặc thực hiện sai hành động

## 📝 **Ghi chú**
- Nói rõ ràng và không quá nhanh
- Đảm bảo môi trường yên tĩnh khi test
- Có thể thử lại nếu lần đầu không nhận diện được