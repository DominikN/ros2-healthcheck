FROM ros:humble-ros-base

SHELL ["/bin/bash", "-c"]

WORKDIR /ros2_ws

RUN mkdir src/ && cd src/ && \
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    ros2 pkg create healthcheck_pkg --build-type ament_cmake --dependencies rclcpp std_msgs

COPY healthcheck.cpp /ros2_ws/src/healthcheck_pkg/src

# Modify the CMakeLists.txt to include the executable
RUN sed -i '/find_package(std_msgs REQUIRED)/a add_executable(healthcheck_node src/healthcheck.cpp)\nament_target_dependencies(healthcheck_node rclcpp std_msgs)\ninstall(TARGETS healthcheck_node DESTINATION lib/${PROJECT_NAME})' /ros2_ws/src/healthcheck_pkg/CMakeLists.txt

# Build the package
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --symlink-install

# Source the workspace
RUN echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

# Add source command to /ros_entrypoint.sh
RUN sed -i 's|^exec "\$@"|source "/ros2_ws/install/setup.bash" --\nexec "$@"|' /ros_entrypoint.sh

# The command to run when the container starts
CMD ["ros2", "run", "healthcheck_pkg", "healthcheck_node"]