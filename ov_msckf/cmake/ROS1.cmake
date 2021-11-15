cmake_minimum_required(VERSION 3.3)

# Find ROS build system
find_package(catkin QUIET COMPONENTS roscpp rosbag tf std_msgs geometry_msgs sensor_msgs nav_msgs visualization_msgs image_transport cv_bridge ov_core ov_init)

# Describe ROS project
option(ENABLE_ROS "Enable or disable building with ROS (if it is found)" ON)
if (catkin_FOUND AND ENABLE_ROS)
    add_definitions(-DROS_AVAILABLE=1)
    catkin_package(
            CATKIN_DEPENDS roscpp rosbag tf std_msgs geometry_msgs sensor_msgs nav_msgs visualization_msgs image_transport cv_bridge ov_core ov_init
            INCLUDE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/src/
            LIBRARIES ov_msckf_lib
    )
else ()
    add_definitions(-DROS_AVAILABLE=0)
    message(WARNING "BUILDING WITHOUT ROS!")
endif ()


# Include our header files
include_directories(
        src
        ${EIGEN3_INCLUDE_DIR}
        ${Boost_INCLUDE_DIRS}
        ${catkin_INCLUDE_DIRS}
)

# Set link libraries used by all binaries
list(APPEND thirdparty_libraries
        ${Boost_LIBRARIES}
        ${OpenCV_LIBRARIES}
        ${catkin_LIBRARIES}
)

# If we are not building with ROS then we need to manually link to its headers
# This isn't that elegant of a way, but this at least allows for building without ROS
# See this stackoverflow answer: https://stackoverflow.com/a/11217008/7718197
if (NOT catkin_FOUND OR NOT ENABLE_ROS)
    message(WARNING "MANUALLY LINKING TO OV_CORE LIBRARY....")
    include_directories(${ov_core_SOURCE_DIR}/src/)
    list(APPEND thirdparty_libraries ov_core_lib)
    message(WARNING "MANUALLY LINKING TO OV_INIT LIBRARY....")
    include_directories(${ov_init_SOURCE_DIR}/src/)
    list(APPEND thirdparty_libraries ov_init_lib)
endif ()

##################################################
# Make the shared library
##################################################

list(APPEND library_source_files
        src/sim/Simulator.cpp
        src/state/State.cpp
        src/state/StateHelper.cpp
        src/state/Propagator.cpp
        src/core/VioManager.cpp
        src/update/UpdaterHelper.cpp
        src/update/UpdaterMSCKF.cpp
        src/update/UpdaterSLAM.cpp
        src/update/UpdaterZeroVelocity.cpp
)
if (catkin_FOUND AND ENABLE_ROS)
    list(APPEND library_source_files
            src/ros/ROS1Visualizer.cpp
    )
endif ()
add_library(ov_msckf_lib SHARED ${library_source_files})
target_link_libraries(ov_msckf_lib ${thirdparty_libraries})
target_include_directories(ov_msckf_lib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/src/)
install(TARGETS ov_msckf_lib
        LIBRARY         DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME         DESTINATION ${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER   DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

##################################################
# Make binary files!
##################################################

if (catkin_FOUND AND ENABLE_ROS)

    add_executable(run_serial_msckf src/ros_serial_msckf.cpp)
    target_link_libraries(run_serial_msckf ov_msckf_lib ${thirdparty_libraries})

    add_executable(run_subscribe_msckf src/ros_subscribe_msckf.cpp)
    target_link_libraries(run_subscribe_msckf ov_msckf_lib ${thirdparty_libraries})

endif ()

add_executable(run_simulation src/run_simulation.cpp)
target_link_libraries(run_simulation ov_msckf_lib ${thirdparty_libraries})

add_executable(test_sim_meas src/test_sim_meas.cpp)
target_link_libraries(test_sim_meas ov_msckf_lib ${thirdparty_libraries})
install(TARGETS test_sim_meas
        LIBRARY         DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME         DESTINATION ${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER   DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

add_executable(test_sim_repeat src/test_sim_repeat.cpp)
target_link_libraries(test_sim_repeat ov_msckf_lib ${thirdparty_libraries})
install(TARGETS test_sim_repeat
        LIBRARY         DESTINATION ${CMAKE_INSTALL_LIBDIR}
        RUNTIME         DESTINATION ${CMAKE_INSTALL_BINDIR}
        PUBLIC_HEADER   DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)





