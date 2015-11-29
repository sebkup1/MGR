
# PlanAhead Launch Script for Post-Synthesis floorplanning, created by Project Navigator

create_project -name mgr -dir "C:/studia/MGR/FPGA/mgr/planAhead_run_2" -part xc6slx45fgg676-3
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "C:/studia/MGR/FPGA/mgr/main.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {C:/studia/MGR/FPGA/mgr} }
set_property target_constrs_file "constr.ucf" [current_fileset -constrset]
add_files [list {constr.ucf}] -fileset [get_property constrset [current_run]]
link_design
