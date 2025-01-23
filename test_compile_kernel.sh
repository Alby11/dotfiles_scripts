#!/bin/bash

# Set up variables
KERNEL_DIR="/tmp/linux-kernel"

# Install necessary packages
sudo dnf install -y git ncurses-devel make gcc bc bison flex elfutils-libelf-devel openssl-devel lm_sensors sysstat

# Start monitoring
sensors >/tmp/sensors_before.txt
sar -u 1 >/tmp/cpu_usage.txt &
sar -r 1 >/tmp/ram_usage.txt &
sar -b 1 >/tmp/io_usage.txt &

# Record start time
start_time=$(date +%s)

# Clone the Linux kernel repository
git clone https://github.com/torvalds/linux.git "$KERNEL_DIR"

# Change to the kernel directory
cd "$KERNEL_DIR" || exit

# Configure the kernel with default settings
make defconfig

# Compile the kernel using all available CPU cores
make -j$(nproc)

# Clean up build files
make clean

# Record end time
end_time=$(date +%s)

# Stop monitoring
killall sar
sensors >/tmp/sensors_after.txt

# Calculate time spent
time_spent=$((end_time - start_time))

# Clean up the kernel directory
rm -rf "$KERNEL_DIR"

# Calculate temperature stats
awk '/^Core/ {print $3}' /tmp/sensors_before.txt /tmp/sensors_after.txt |
  awk -F'+' '{sum+=$2; if($2>max) max=$2} END {print "Max Temp: " max "°C, Avg Temp: " sum/NR "°C"}'

# Calculate CPU usage stats
awk '/Average/ {print "Max CPU: " $3 "%, Avg CPU: " $3 "%"}' /tmp/cpu_usage.txt

# Calculate RAM usage stats
awk '/Average/ {print "Max RAM: " $4 "kB, Avg RAM: " $4 "kB"}' /tmp/ram_usage.txt

# Calculate IO usage stats
awk '/Average/ {print "Max IO: " $3 "tps, Avg IO: " $3 "tps"}' /tmp/io_usage.txt

# Print time spent
echo "Time spent: $((time_spent / 60)) minutes and $((time_spent % 60)) seconds"

# Notify completion
echo "Kernel compilation and cleanup completed in $KERNEL_DIR"
