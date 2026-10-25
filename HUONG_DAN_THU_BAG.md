# Hướng dẫn calibrate IMU và thu bag trên Go2

Tài liệu này dành cho người trực tiếp thao tác với robot. Bạn cần làm 2 việc rồi gửi lại kết quả:

1. **Calibrate IMU** của con Go2 (khoảng 1 phút, robot tự di chuyển), tạo ra file `imu_calib_data.yaml`.
2. **Thu bag** dữ liệu lidar + IMU trong lúc điều khiển robot đi quanh khu vực cần lập bản đồ.

Mọi thao tác đều làm trên **máy tính onboard của Go2**. Không cần chạy hệ thống tự hành; chỉ dùng 2 lệnh `calibrate_imu` và `ros2 bag record`.

**Yêu cầu:** Go2 bản **EDU** (bản Air/Pro không truy cập được dữ liệu lidar), pin đầy, tay cầm Unitree để điều khiển robot.

## 1. Chuẩn bị

1. Kết nối màn hình + bàn phím vào máy onboard (hoặc SSH vào), đăng nhập (mật khẩu mặc định `123`).
2. Mở terminal. Khi được hỏi chọn ROS, bấm **`1`** (ROS2 Foxy).
3. Kết nối máy onboard với **WiFi có internet**, rồi kiểm tra giờ hệ thống:
   ```bash
   date
   ```
   Nếu giờ đang là năm 1970 thì chờ vài phút sau khi có WiFi để giờ tự cập nhật. Giờ sai sẽ làm `git clone` lỗi.

## 2. Tải code và build phần calibrate

```bash
cd ~
git clone https://github.com/go2lifelongmapping/go2_autonomy_ws.git
cd go2_autonomy_ws
colcon build --packages-up-to calibrate_imu
source install/setup.bash
```

Nếu build báo thiếu `rosidl_generator_dds_idl`:
```bash
sudo apt install ros-foxy-rosidl-generator-dds-idl
```
rồi chạy lại lệnh `colcon build` ở trên.

Kiểm tra máy onboard nhận được dữ liệu lidar:
```bash
ros2 topic list | grep utlidar
```
Phải thấy `/utlidar/cloud` và `/utlidar/imu`. Nếu không thấy, dừng lại và báo cho người nhờ bạn.

## 3. Calibrate IMU

1. Đặt robot trên **sàn phẳng**, cho robot **đứng dậy** ở chế độ bình thường. Dọn trống khoảng **1.5 m** xung quanh.
2. Tạo thư mục lưu kết quả (tool không tự tạo):
   ```bash
   mkdir -p ~/Desktop
   ```
3. Chạy (cầm sẵn tay cầm Unitree để dừng robot nếu có gì bất thường):
   ```bash
   ros2 run calibrate_imu calibrate_imu
   ```
   Robot sẽ tự làm theo thứ tự, **không chạm vào robot trong lúc này**:

   | Thời gian | Robot làm gì |
   |---|---|
   | 0–2 s | Bước tại chỗ |
   | 2–15 s | Đứng yên |
   | 15–35 s | Xoay trái tại chỗ |
   | ~37 s | In `Calibration finished!` và thoát |

4. Kiểm tra kết quả:
   ```bash
   cat ~/Desktop/imu_calib_data.yaml
   ```
   Phải có 8 dòng (`acc_bias_x` … `ang_z2y_proj`), tất cả là số, **không có `nan`**. Nếu có `nan` hoặc file không tồn tại, chạy lại bước 3.

## 4. Thu bag

1. Tạo thư mục chứa bag và kiểm tra dung lượng trống (mỗi phút thu khoảng 45 MB):
   ```bash
   mkdir -p ~/go2_bags
   df -h ~
   ```
2. Đặt robot đứng ở **điểm xuất phát** và ghi nhớ vị trí này (đánh dấu trên sàn nếu được).
3. Bắt đầu thu. Đặt tên bag theo dạng `<địa_điểm>_<ngày>_<số thứ tự>`:
   ```bash
   ros2 bag record -o ~/go2_bags/lab_20261026_01 /utlidar/cloud /utlidar/imu
   ```
4. Trong lúc thu, điều khiển robot bằng tay cầm Unitree:
   - **Đứng yên 5–10 giây** ngay sau khi bắt đầu thu.
   - Đi **chậm và đều**, rẽ từ từ, **tránh xoay nhanh tại chỗ**.
   - Đi qua hết khu vực cần lập bản đồ, mỗi chỗ ít nhất một lần.
   - Cuối cùng **quay về đúng điểm xuất phát**, đứng yên 5 giây.
   - Độ dài hợp lý: 2–10 phút mỗi bag. Khu vực lớn thì chia thành nhiều bag.
5. Bấm **`Ctrl+C`** trong terminal để dừng thu.
6. Kiểm tra bag:
   ```bash
   ros2 bag info ~/go2_bags/lab_20261026_01
   ```
   Phải có cả 2 topic. Số message gần đúng với:
   - `/utlidar/cloud`: khoảng **15 × số giây** thu
   - `/utlidar/imu`: khoảng **250 × số giây** thu

   Nếu thiếu topic hoặc số message quá ít, thu lại.

**Không dùng** `ros2 bag record -a`, **không bật** tuỳ chọn nén.

## 5. Gửi lại kết quả

Gửi lại 2 thứ (qua USB hoặc cách nào tiện):

1. **Cả thư mục** của từng bag trong `~/go2_bags/` (mỗi thư mục gồm file `.db3` và `metadata.yaml`).
2. File `~/Desktop/imu_calib_data.yaml`.

Ví dụ copy sang USB (thay `<USB>` bằng tên USB trong `/media/$USER/`):
```bash
cp -r ~/go2_bags ~/Desktop/imu_calib_data.yaml /media/$USER/<USB>/
```

Kèm theo ghi chú ngắn: con Go2 nào (số serial nếu có), ngày, địa điểm, và bất cứ điều gì bất thường (robot vấp, có người đi qua nhiều, v.v.).

## Checklist trước khi gửi

- [ ] `imu_calib_data.yaml` có đủ 8 dòng số, không có `nan`
- [ ] File calibrate và bag thu trên **cùng một con Go2**
- [ ] Mỗi bag có đủ `/utlidar/cloud` (~15 Hz) và `/utlidar/imu` (~250 Hz)
- [ ] Mỗi bag bắt đầu bằng 5–10 giây đứng yên và kết thúc ở điểm xuất phát
- [ ] Gửi **cả thư mục** bag (có `metadata.yaml`), không chỉ file `.db3`
- [ ] Có ghi chú: con robot nào, ngày, địa điểm, điều gì bất thường
