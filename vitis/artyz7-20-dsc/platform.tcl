# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/gonzalo/workspace/comm/mse-communication/vitis/artyz7-20-dsc/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/gonzalo/workspace/comm/mse-communication/vitis/artyz7-20-dsc/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {artyz7-20-dsc}\
-hw {/home/gonzalo/workspace/comm/mse-communication/hw/dsc-artyz7-20.xsa}\
-proc {ps7_cortexa9_0} -os {freertos10_xilinx} -out {/home/gonzalo/workspace/comm/mse-communication/vitis}

platform write
platform generate -domains 
platform active {artyz7-20-dsc}
bsp reload
bsp reload
bsp write
platform generate
