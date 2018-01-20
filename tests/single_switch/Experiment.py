#!/usr/bin/python
'''
Usage: Experiment.py TestbedFolder -> Run experiment
       Experiment.py clean -> Clean testbed
'''
import subprocess
import time
import sys

class Experiment:

    def __init__(self):
        self.number_of_hosts = 12
        self.folder = "."

    def run_cmd(self, cmd):
        print cmd

        result = ""
        try:
            result = subprocess.check_output("sudo "+cmd, shell=True)
        except subprocess.CalledProcessError as e:
            result = "\033[91m"+result+"\033[0m"
            print "\033[91m"+e.output+"\033[0m"

        return result

    def run(self):

        cmdline = ""

        # veth pairs
        for i in range(1, self.number_of_hosts+2):
            print self.run_cmd("ip link add dev h%d-sw type veth peer name sw-h%d"%(i,i))
            print self.run_cmd("ifconfig h%d-sw hw ether 00:25:90:8a:c5:0%s"%(i,hex(i)[-1]))
            print self.run_cmd("ip link set dev h%d-sw up"%i)
            print self.run_cmd("ip link set dev sw-h%d up"%i)
            cmdline += " -i "+str(i-1)+"@sw-h%d"%i

        # Run switch
        print self.run_cmd("docker image pull p4lang/behavioral-model")
        print self.run_cmd("screen -S bmv2 -d -m docker container run --name bmv2 --cpuset-cpus=\"4,5,6,7\" --network host -v "+self.folder+":/Testbed -e CMD_LINE=\""+cmdline+"\" -ti p4lang/behavioral-model bash")

        # Run hosts
        print self.run_cmd("mkdir /var/run/netns")
        for i in range(1, self.number_of_hosts+2):

            print self.run_cmd("screen -S h"+str(i)+" -d -m docker container run --name h"+str(i)+" -h h"+str(i)+" --cpuset-cpus=\""+str(7+(i*2)-1)+","+str(7+(i*2))+"\" --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -v "+self.folder+":/Testbed -ti openjdk bash")

            time.sleep(10)

            # Install packages
            print self.run_cmd("docker container exec h"+str(i)+" apt-get update")
            #result = self.run_cmd("docker container exec h"+str(i)+" apt-get install -y net-tools iproute2 iputils-ping vim ethtool ")
            result = self.run_cmd("docker container exec h"+str(i)+" apt-get install -y ethtool ")
            print result[len(result)-6:len(result)]

            # Set netns
            pid = int(self.run_cmd("docker inspect --format '{{.State.Pid}}' h"+str(i)))
            print self.run_cmd("ln  -s /proc/"+str(pid)+"/ns/net /var/run/netns/ns-h"+str(i))
            print self.run_cmd("ip link set h"+str(i)+"-sw netns ns-h"+str(i))

            # Set IP
            print self.run_cmd("ip netns exec ns-h"+str(i)+" ifconfig h"+str(i)+"-sw 11.0.0."+str(i)+"/24")

            # Set arp
            for k in range(1, self.number_of_hosts+2):
                print self.run_cmd("ip netns exec ns-h"+str(i)+" arp -s 11.0.0."+str(k)+" 00:25:90:8a:c5:0"+hex(k)[-1]+" -i h"+str(i)+"-sw")

            # Copy data locally
            print self.run_cmd("docker container exec h"+str(i)+" cp -r /Testbed/DAIET-MapReduce /")

            # Disable TCP offload
            print self.run_cmd("docker container exec h"+str(i)+" ethtool --offload h"+str(i)+"-sw rx off tx off")
            print self.run_cmd("docker container exec h"+str(i)+" ethtool -K h"+str(i)+"-sw gso off") 

        # Start switch
        print self.run_cmd("docker container exec bmv2 cp -r /Testbed/DAIET/daiet.json /")
        print self.run_cmd("screen -S bmv2_2 -d -m docker container exec bmv2 simple_switch /daiet.json "+cmdline+" --log-file daiet --log-flush")
        time.sleep(5)

        # Set flow rules
        for i in range(1, self.number_of_hosts+2):
            print self.run_cmd("docker container exec bmv2 /Testbed/DAIET/tests/single_switch/add_rule.sh \"table_add mac_forwarding_table set_port 00:25:90:8a:c5:0%s => %d\""%(hex(i)[-1],i-1))

        # Start DAIET-MapReduce

        ## At all workers
        for i in range(1, self.number_of_hosts+2):
            print self.run_cmd("docker container exec h"+str(i)+" nohup /DAIET-MapReduce/dist/bin/registry 7777 > /dev/null 2>&1 &")

            # Set hostname resolution
            for j in range(1, self.number_of_hosts+2):
                print self.run_cmd("docker container exec h"+str(i)+" /Testbed/DAIET/tests/single_switch/write_hosts.sh \"11.0.0."+str(j)+" h"+str(j)+"\"")

        time.sleep(10)

        ## At the master
        print self.run_cmd("docker container exec h"+str(self.number_of_hosts+1)+" nohup /DAIET-MapReduce/dist/bin/dfs-master -l dfsmaster.log -rp 7777 > /dev/null 2>&1 &")

        # Copy data file
        print self.run_cmd("docker container exec h"+str(self.number_of_hosts+1)+" cp /Testbed/random_text_500mb.txt /")

        time.sleep(10)

        ## At the slaves
        for i in range(1, self.number_of_hosts+1):
            print self.run_cmd("docker container exec h"+str(i)+" nohup /DAIET-MapReduce/dist/bin/dfs-slave -d data_dir -mh 11.0.0."+str(self.number_of_hosts+1)+" -mp 7777 -rp 7777 -n 11.0.0."+str(i)+" > /dev/null 2>&1 &")

        ## At the master
        print self.run_cmd("docker container exec h"+str(self.number_of_hosts+1)+" nohup /DAIET-MapReduce/dist/bin/mapreduce-jobtracker -dh 11.0.0."+str(self.number_of_hosts+1)+" -dp 7777 -rp 7777 -fp 8888 -t temp_dir > /dev/null 2>&1 &")
        
        time.sleep(5)

        ## At the slaves
        for i in range(1, self.number_of_hosts+1):
            print self.run_cmd("docker container exec h"+str(i)+" nohup /DAIET-MapReduce/dist/bin/mapreduce-tasktracker -dh 11.0.0."+str(self.number_of_hosts+1)+" -dp 7777 -jh 11.0.0."+str(self.number_of_hosts+1)+" -jp 7777 -rp 7777 -fp 8889 -t TEMP_DIR > /dev/null 2>&1 &")

    def clean(self):

        # Stop switch
        print self.run_cmd("docker container stop bmv2")
        print self.run_cmd("docker container rm bmv2")

        for i in range(1, self.number_of_hosts+2):

            # Stop hosts
            print self.run_cmd("docker container stop h"+str(i))
            print self.run_cmd("docker container rm h"+str(i))

            # Remove netns
            print self.run_cmd("rm /var/run/netns/ns-h"+str(i))

            # Remove veths
            print self.run_cmd("ip link del sw-h"+str(i))
            print self.run_cmd("ip link del h"+str(i)+"-sw")

if __name__ == '__main__':

    exp = Experiment()

    if len(sys.argv)==2 and sys.argv[1]=="clean":

        print "\033[1m### Cleaning ### \033[0m"
        exp.clean()

    else:
        print "\033[1m### Starting ### \033[0m"

        if len(sys.argv)==2:
            exp.folder = sys.argv[1]

        print "\033[1m# Working directory: "+exp.folder+"  # \033[0m"
        exp.run()
