cmake_minimum_required(VERSION 3.15)

message(STATUS "=== Starting TetherKit Auto-Connect Installer ===")

# 1. Detect Homebrew and install tetherkit-cli (Must run as normal user, not root)
find_program(BREW_BIN brew PATHS /opt/homebrew/bin /usr/local/bin)
if(NOT BREW_BIN)
    message(FATAL_ERROR "Homebrew not found! Install Homebrew first from https://brew.sh")
endif()

find_program(TETHERKIT_BIN tetherkit-cli PATHS /opt/homebrew/bin /usr/local/bin)
if(NOT TETHERKIT_BIN)
    message(STATUS "Installing tetherkit-cli via Homebrew...")
    execute_process(
        COMMAND "${BREW_BIN}" install XiaoMiku01/tap/tetherkit-cli
        RESULT_VARIABLE BREW_RES
    )
    if(NOT BREW_RES EQUAL 0)
        message(FATAL_ERROR "Failed to install tetherkit-cli via Homebrew.")
    endif()
    find_program(TETHERKIT_BIN tetherkit-cli PATHS /opt/homebrew/bin /usr/local/bin REQUIRED)
endif()

message(STATUS "Found tetherkit-cli at: ${TETHERKIT_BIN}")

# 2. Generate the tetherkit-auto.sh script in /tmp
set(TEMP_SH "/tmp/tetherkit-auto.sh")
file(WRITE "${TEMP_SH}" "#!/bin/bash
CLI_BIN=\"${TETHERKIT_BIN}\"

while true; do
    # Check if an RNDIS device is connected
    if \"\$CLI_BIN\" --list 2>/dev/null | grep -qiE \"0x|rndis|android|gadget|device\"; then
        echo \"RNDIS device detected. Starting TetherKit...\"

        LOG_FILE=\"/tmp/tetherkit-auto.log\"
        > \"\$LOG_FILE\"
        \"\$CLI_BIN\" > \"\$LOG_FILE\" 2>&1 &
        CLI_PID=\$!

        # Wait up to 10 seconds for the feth interface name to appear
        IFACE=\"\"
        for i in {1..20}; do
            IFACE=\$(grep -oE \"feth[0-9]+\" \"\$LOG_FILE\" | head -n 1)
            if [ -n \"\$IFACE\" ]; then
                break
            fi
            sleep 0.5
        done

        # Request an IP address via DHCP
        if [ -n \"\$IFACE\" ]; then
            echo \"Configuring DHCP on \$IFACE...\"
            /usr/sbin/ipconfig set \"\$IFACE\" DHCP
        fi

        # Keep waiting until the phone is unplugged and tetherkit-cli exits
        wait \$CLI_PID
        echo \"Device disconnected.\"
    fi
    sleep 3
done
")

# 3. Generate the LaunchDaemon plist in /tmp
set(TEMP_PLIST "/tmp/com.user.tetherkit.auto.plist")
file(WRITE "${TEMP_PLIST}" "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">
<plist version=\"1.0\">
<dict>
    <key>Label</key>
    <string>com.user.tetherkit.auto</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/tetherkit-auto.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/tetherkit-daemon.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/tetherkit-daemon.err</string>
</dict>
</plist>
")

# 4. Install files and bootstrap LaunchDaemon using sudo
message(STATUS "Installing system files and starting LaunchDaemon (enter Mac password if prompted)...")

execute_process(COMMAND sudo mkdir -p /usr/local/bin RESULT_VARIABLE RES1)
execute_process(COMMAND sudo mv "${TEMP_SH}" /usr/local/bin/tetherkit-auto.sh RESULT_VARIABLE RES2)
execute_process(COMMAND sudo chown root:wheel /usr/local/bin/tetherkit-auto.sh RESULT_VARIABLE RES3)
execute_process(COMMAND sudo chmod 755 /usr/local/bin/tetherkit-auto.sh RESULT_VARIABLE RES4)

execute_process(COMMAND sudo mv "${TEMP_PLIST}" /Library/LaunchDaemons/com.user.tetherkit.auto.plist RESULT_VARIABLE RES5)
execute_process(COMMAND sudo chown root:wheel /Library/LaunchDaemons/com.user.tetherkit.auto.plist RESULT_VARIABLE RES6)
execute_process(COMMAND sudo chmod 644 /Library/LaunchDaemons/com.user.tetherkit.auto.plist RESULT_VARIABLE RES7)

# Unload existing daemon if already running (ignore errors if not loaded)
execute_process(
    COMMAND sudo launchctl bootout system /Library/LaunchDaemons/com.user.tetherkit.auto.plist
    ERROR_QUIET
)

# Bootstrap the service
execute_process(
    COMMAND sudo launchctl bootstrap system /Library/LaunchDaemons/com.user.tetherkit.auto.plist
    RESULT_VARIABLE BOOT_RES
)

if(BOOT_RES EQUAL 0)
    message(STATUS "=== SUCCESS! TetherKit auto-connect is now active! ===")
else()
    message(FATAL_ERROR "Failed to bootstrap LaunchDaemon (exit code: ${BOOT_RES}).")
endif()
