
echo "COMPILE + SETUP + SLEEP 3 SECONDS\n"
erl < compile.erl > /dev/null
sh integration_test/startup_cluster.sh > /dev/null &

sleep 3

echo "STARTING THE TEST\n"

# Test
erl < integration_test/test.erl -sname unique_name -setcookie magic

echo "\nENDING TEST + CLEANUP\n"

killall beam.smp

sleep 2

rm *_active_table
rm *_inactive_table

killall sh
