# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/gonzalo/workspace/Comunicaciones/mse-communication/vitis/dsc-artyz7/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/gonzalo/workspace/Comunicaciones/mse-communication/vitis/dsc-artyz7/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {dsc-artyz7}\
-hw {/home/gonzalo/workspace/Comunicaciones/mse-communication/hw/dsc-artyz7-20.xsa}\
-proc {ps7_cortexa9_0} -os {freertos10_xilinx} -out {/home/gonzalo/workspace/Comunicaciones/mse-communication/vitis}

platform write
platform generate -domains 
platform active {dsc-artyz7}
domain active {zynq_fsbl}
bsp reload
domain active {freertos10_xilinx_domain}
bsp reload
bsp write
platform generate
