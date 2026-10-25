# Docker ROS2 Foxy cho autonomy_stack_go2

Môi trường Ubuntu 20.04 + ROS2 Foxy + CycloneDDS 0.10.x (bản Go2 dùng) để build và chạy repo trên máy x86 bất kỳ (đã thử trên Ubuntu 22.04). Không dùng cho máy onboard của Go2 (Jetson ARM, đã có Foxy sẵn).

## Yêu cầu

- Docker + Docker Compose, user thuộc group `docker`
- Phiên X11 (RViz, Unity); GPU Intel/AMD được dùng qua `/dev/dri`

## Lần đầu

```bash
git clone <repo này> autonomy_stack_go2
cd autonomy_stack_go2
./docker/run.sh            # build image (lần đầu ~10 phút) và mở shell trong container
colcon build --symlink-install --cmake-args -DCMAKE_BUILD_TYPE=Release
```

Mỗi terminal mới: chạy lại `./docker/run.sh` (dùng chung container đang chạy). Dừng hẳn: `cd docker && docker compose down`.

## Thư mục

| Trên máy host | Trong container | Nội dung |
|---|---|---|
| `autonomy_stack_go2/` | `~/autonomy_stack_go2` | Code, `build/`, `install/` |
| `autonomy_stack_go2/calib/` | `~/Desktop` | `imu_calib_data.yaml` (riêng cho từng con Go2) |
| `autonomy_stack_go2/bags/` | `~/autonomy_stack_go2/bags` | Bagfile |

`calib/` và `bags/` không được đưa lên git.

## Mô phỏng

Giải nén model Unity vào `src/base_autonomy/vehicle_simulator/mesh/unity/`, rồi trong container:

```bash
./system_simulation.sh                        # hoặc ./system_simulation_with_route_planner.sh
```

Sau khi tắt bằng Ctrl+C, Unity vẫn chạy nền: `pkill -f Model.x86_64`.

## Chạy bag

Không cắm dây Ethernet vào Go2. Đặt `imu_calib_data.yaml` của đúng con robot đã thu bag vào `calib/`.

```bash
./system_real_robot.sh                        # terminal 1
ros2 bag play bags/<tên bag>                  # terminal 2
```

Mỗi lần phát lại bag phải khởi động lại `system_real_robot.sh`.

## Robot thật (Go2 EDU, qua Ethernet)

Trên host, đặt IP cho cổng nối với Go2 (ví dụ `eno1`):

```bash
sudo nmcli con add type ethernet ifname eno1 con-name go2 \
  ipv4.method manual ipv4.addresses 192.168.123.100/24 ipv4.never-default yes
sudo nmcli con up go2
```

Trong container:

```bash
source /opt/unitree_ros2_setup.sh             # cổng khác eno1: export GO2_IFACE=<tên> trước
ros2 topic list | grep utlidar                # phải thấy /utlidar/cloud, /utlidar/imu
ros2 run calibrate_imu calibrate_imu          # 1 lần cho mỗi con Go2, robot sẽ tự bước/xoay
ros2 bag record -o bags/<tên> /utlidar/cloud /utlidar/imu
./system_real_robot.sh
```

Không dùng `unitree_setup.sh` ở thư mục gốc repo (nó source ROS Humble và card mạng `enp3s0`).
