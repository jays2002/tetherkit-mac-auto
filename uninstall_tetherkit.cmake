cmake_minimum_required(VERSION 3.15)

message(STATUS "=== Uninstalling TetherKit Auto-Connect ===")

execute_process(
    COMMAND sudo launchctl bootout system /Library/LaunchDaemons/com.user.tetherkit.auto.plist
    ERROR_QUIET
)

execute_process(COMMAND sudo rm -f /Library/LaunchDaemons/com.user.tetherkit.auto.plist)
execute_process(COMMAND sudo rm -f /usr/local/bin/tetherkit-auto.sh)
execute_process(COMMAND sudo rm -f /tmp/tetherkit-auto.log /tmp/tetherkit-daemon.log /tmp/tetherkit-daemon.err)

message(STATUS "=== Uninstalled cleanly! ===")
