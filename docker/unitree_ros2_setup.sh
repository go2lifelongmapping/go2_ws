#!/bin/bash
# Source before talking to the real Go2 (IMU calibration, system_real_robot*.sh, ros2 topic list).
# Pins CycloneDDS to the Ethernet port wired to Go2; override with GO2_IFACE=<iface>.
source /opt/ros/foxy/setup.bash
source /opt/cyclonedds_ws/install/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export CYCLONEDDS_URI="<CycloneDDS><Domain><General><Interfaces>
                            <NetworkInterface name=\"${GO2_IFACE:-eno1}\" priority=\"default\" multicast=\"default\" />
                        </Interfaces></General></Domain></CycloneDDS>"
if [ -f ~/autonomy_stack_go2/install/setup.bash ]; then
    source ~/autonomy_stack_go2/install/setup.bash
fi
echo "Unitree ROS2 env ready (CycloneDDS on ${GO2_IFACE:-eno1})"
