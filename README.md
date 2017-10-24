# DAIET: Data Aggregation In-nETwork 


## Resources
* DAIET project website: [sands.kaust.edu.sa/daiet/](http://sands.kaust.edu.sa/daiet/)
* HotNets 2017 paper: 
  
  *Amedeo Sapio, Ibrahim Abdelaziz, Abdulla Aldilaijan, Marco Canini, and Panos Kalnis <br>
  **In-Network Computation is a ~~Dumb~~ Idea Whose Time Has Come** <br>
  In Proceedings of the 16th ACM Workshop on Hot Topics in Networks. ACM, 2017.*

## ACM HotNets 2017 Experiment:
Note: tested with Ubuntu 17.04 Zesty Zapus (amd64) on May, 2017. 

1. Install dependencies: 
net-tools, git, python, python-pip, screen, maven, openjdk-8-jdk, docker
```bash
sudo apt-get update
sudo apt-get install -y \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual \
    git python python-pip screen maven net-tools \
    openjdk-8-jdk \
    apt-transport-https ca-certificates curl \
    software-properties-common

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
export PATH=$PATH:/usr/lib/jvm/java-8-openjdk-amd64/bin

# Install docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    | sudo apt-key add -

# Currently there is no docker repo for Zesty, 
# so we use Xenial’s.
sudo add-apt-repository \
   "deb [arch=amd64]
   https://download.docker.com/linux/ubuntu \
   xenial stable"

sudo apt-get update
sudo apt-get install -y docker-ce
sudo service docker start
```
2. Clone the P4 compiler repository and install it:
```bash
git clone https://github.com/p4lang/p4c-bm.git
cd p4c-bm
sudo pip install -r requirements.txt
sudo pip install -r requirements_v1_1.txt
sudo python setup.py install
cd ..
```
3. Clone the DAIET and simpleMR repositories:
```bash
git clone https://github.com/AmedeoSapio/DAIET 
git clone https://github.com/ibrahimabdelaziz/simplemr
```
4. Compile DAIET:
```bash
cd DAIET
p4c-bmv2 p4src/daiet.p4 --json daiet.json
cd ..
```
5. Compile simpleMR:
```bash
cd simplemr
mvn package
chmod +x dist/bin/*
cd ..
```
6. Extract the dataset:
```bash
unzip DAIET/tests/single_switch/random_text_500mb.zip
```
7. We pin the container running the switch on the cores {4,5,6,7} and the 12 hosts containers on the cores from 8 to 31. You must change the parameter: “--cpuset-cpus”  **twice** in “DAIET/tests/single_switch/Experiment.py” if you don’t have enough cores. 
We also isolated those cores from kernel scheduling using the “isolcpus” kernel parameter.

8. *Optional*: To run the experiment using a RAMdisk, we changed Docker's storage base directory (where container and images go) using the -g option when starting the Docker daemon. 
You can mount a RAMdisk (tmpfs) on the folder “/memfs” and then edit the “/etc/default/docker” file with the -g option: 
```bash
# In /etc/default/docker
DOCKER_OPTS="-dns 8.8.8.8 -dns 8.8.4.4 -g /memfs"
```
Restart docker afterwards:
```bash
service docker restart
```

9. Start the testbed:
```bash
wd=`pwd`
cd DAIET/tests/single_switch/
./Experiment.py ${wd}
```

10. Run a job once without using DAIET. This is needed because simpleMR assigns the reduce tasks (and thus the reducer ID used as tree ID in the packets) randomly among the workers. We can see the assignment in a first job and predict the assignment for the next job, which follows the same order. In a future version, the jobtracker would push the rules in the switch when a new reduce task is scheduled.
```bash
sudo screen -r h13
# Now you are in the master container

# Load the data file in the DFS
./simplemr/dist/bin/dfs-load -rh h13 -rp 7777 -r 12 \
    random_text_500mb.txt

# Start a job without DAIET (24 mappers, 12 reducers)
./simplemr/dist/bin/examples-wordcount \
    random_text_500mb.txt result.txt -m 24 -r 12 -rh h13 \
    -rp 7777

# Check the job status
./simplemr/dist/bin/mapreduce-jobs -rh h13 -rp 7777
```
Wait for the end of the job and then press “CTRL+A” and “D” to exit from the master container.

11. Extract the reducer IDs from the logs:
```bash
sudo ./extract_reducer_id.sh
```
This command prints 12 integers. You have to add 36 (number of mapper and reducers) to each one of them and use the result to update the file “DAIET/tests/single_switch/commands.txt” (replace “XX“ with the new values).
Specifically, the integers must be used as matching value in the “tree_id_adapter_table” and “forwarding_table”. 

12. Add the flow rules to the switch:
```bash
sudo screen -r bmv2
# Now you are in the switch container

simple_switch_CLI \
    < /Testbed/DAIET/tests/single_switch/commands.txt
```
Press “CTRL+A” and then “D” to exit from the switch container.

13. Run a job with DAIET.
Note that the workers are connected to the switch through the interfaces from sw-h1 to sw-h12 (sw-h13 is the master, which is not a worker).
```bash
sudo screen -r h13
# Now you are in the master container

# Start a job with DAIET (24 mappers, 12 reducers)
./simplemr/dist/bin/examples-wordcount \
    random_text_500mb.txt result.txt -m 24 -r 12 -rh h13 \
    -rp 7777 -nr

# Check the job status
./simplemr/dist/bin/mapreduce-jobs -rh h13 -rp 7777
```
Wait for the end of the job and then press “CTRL+A” and “D” to exit from the master container.

14. The time spent for the reduce phase (in milliseconds) can be printed with:
```bash
sudo ./extract_reduce_time.sh
```
It prints, for each worker, the reducer ID and the reduce time for both jobs, with and without DAIET. The first job have reducer IDs in [24,35] and the second in [60,71].

15. Finally, clean the testbed:
```bash
./Experiment.py clean
```
