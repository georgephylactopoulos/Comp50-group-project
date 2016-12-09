
echo "COMPILE + SETUP + SLEEP 3 SECONDS\n"
erl < compile.erl > /dev/null

rm *_active_table
rm *_inactive_table

erl < start_master.erl -sname master@localhost -master_name master -setcookie magic > /dev/null &

sleep 2

erl < start_monitor.erl -sname monitor -master_node master@localhost -master_name master -refresh_rate 100 -setcookie magic > /dev/null &
# erl < start_health_check.erl -sname health -master_node master@localhost -master_name master -refresh_rate 1000 -copies 3 -setcookie magic > integration_test/health_output.txt &

erl < start_tablet.erl -sname t1@localhost -master_node master@localhost -master_name master -tablet_name t1 -setcookie magic > /dev/null &
erl < start_tablet.erl -sname t2@localhost -master_node master@localhost -master_name master -tablet_name t2 -setcookie magic > /dev/null &
erl < start_tablet.erl -sname t3@localhost -master_node master@localhost -master_name master -tablet_name t3 -setcookie magic > /dev/null &
erl < start_tablet.erl -sname t4@localhost -master_node master@localhost -master_name master -tablet_name t4 -setcookie magic > /dev/null &
erl < start_tablet.erl -sname t5@localhost -master_node master@localhost -master_name master -tablet_name t5 -setcookie magic > /dev/null &
erl < start_tablet.erl -sname t6@localhost -master_node master@localhost -master_name master -tablet_name t6 -setcookie magic > /dev/null &



sleep 3

echo "STARTING THE TEST\n"

# Test
erl < integration_test/potter_test.erl -sname unique_name -setcookie magic

echo "\nENDING TEST + CLEANUP\n"

killall beam.smp

sleep 2

rm *_active_table
rm *_inactive_table

killall sh
