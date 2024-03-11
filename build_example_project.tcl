set buid_dir [ file dirname [ file normalize [ info script ] ] ]

create_project -force QSPI_example ${buid_dir}/QSPI_example -part xc7z014sclg484-1

add_files -fileset sources_1 -norecurse ${buid_dir}/QSPI_master.vhd
add_files -fileset sources_1 -norecurse ${buid_dir}/QSPI_slave.vhd
update_compile_order -fileset sources_1

set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ${buid_dir}/testbench.sv
update_compile_order -fileset sim_1

launch_simulation
open_wave_config ${buid_dir}/tb_behav.wcfg
run 1000 ns