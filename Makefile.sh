#!/bin/sh
```
  Makefile.sh

  By one command,front page and backend will be started.
  run:
    bash Makefile.sh
```


# 先判断系统
SYSTEM=`uname -s`
if [ $SYSTEM = "Linux" ] ;then
    if id|grep docker>>/dev/null;then
        echo
    else
        sudo usermod -aG docker $USER
    fi
fi


# 安装 nvidia-docker 的函数
function install_nvidia_docker() {
    nvidia-docker -v  >> /dev/null
    if [ $? != 0 ] ;then
        echo nvidia-docker has not been installed
        echo "*************** install nvidia-docker *****************"
        sudo groupadd nvidia-docker
        sudo usermod -aG nvidia-docker $USER
        wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
        sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

        nvidia-docker run --rm nvidia/cuda nvidia-smi
    else
        echo below is nvidia-docker information:
        nvidia-docker run --rm nvidia/cuda nvidia-smi
    fi
}


# 构建镜像和启动容器的函数
function build_image_and_start_container() {

    echo "*************** biuld docker image using dockerfile *****************"
    docker build -t sg-ai-keras-images .

    if [ $SYSTEM == "Linux" ];then

        install_nvidia_docker
        echo "*************** run a container using docker with gpu *****************"
        nvidia-docker run -d -p 8888:8888 -p 8081:8081 -p 5000:5000 --name keras-container -v $PWD:/project sg-ai-keras-images
    else
        echo "*************** run a container using docker with cpu *****************"
        docker run -d -p 8888:8888 -p 8081:8081 -p 5000:5000 --name keras-container -v $PWD:/project sg-ai-keras-images
    fi

    echo "*************** Currently running servers: **************************"
    docker exec -it keras-container  jupyter notebook list

    echo "*************** enter the container and run the make.sh *************"
    docker exec -it keras-container /bin/bash /project/make.sh
}


# 主程序，判断各种可能的情况，根据不同的情况去执行不同的命令行或调用不同的函数
docker -v >>/dev/null
if [ $? != 0 ] ;then
    echo " we can't find your dorker,please install docker before using it "

elif docker ps | grep keras-container>> /dev/null; then

    echo "*************** enter the container and run the make.sh *************"
    docker exec -it keras-container /bin/bash /project/make.sh

elif docker ps -a | grep keras-container>> /dev/null; then

    docker start keras-container

    echo "*************** enter the container and run the make.sh *************"
    docker exec -it keras-container /bin/bash /project/make.sh

elif docker images | grep sg-ai-keras-images>> /dev/null; then

    if [ $SYSTEM == "Linux" ];then
        echo "*************** run a container using docker with gpu *****************"
        nvidia-docker run -d -p 8888:8888 -p 8081:8081 -p 5000:5000 --name keras-container -v $PWD:/project sg-ai-keras-images
    else
        echo "*************** run a container using docker with cpu *****************"
        docker run -d -p 8888:8888 -p 8081:8081 -p 5000:5000 --name keras-container -v $PWD:/project sg-ai-keras-images
    fi

    echo "*************** enter the container and run the make.sh *************"
    docker exec -it keras-container /bin/bash /project/make.sh

else
    echo "This is $SYSTEM "
    echo "*************** install npm package *****************"
    npm install
    npm rebuild node-sass
    build_image_and_start_container
fi
