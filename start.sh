#!/bin/bash

echo "\$nrconf{kernelhints} = 0;" >> /etc/needrestart/needrestart.conf
echo "\$nrconf{restart} = 'l';" >> /etc/needrestart/needrestart.conf

# Cysic 代理和证明器安装路径
CYSIC_AGENT_PATH="$HOME/cysic-prover-agent"
CYSIC_PROVER_PATH="$HOME/cysic-aleo-prover"

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 安装必要的依赖
apt update
apt install curl wget -y


# 检查并安装 Node.js 和 npm
if command -v node > /dev/null 2>&1; then
    echo "Node.js 已安装，版本: $(node -v)"
else
    echo "Node.js 未安装，正在安装..."
    curl -fsSL https://deb.nodesource.com/setup_16.x | sudo -E bash -
    sudo apt-get install -y nodejs
fi
if command -v npm > /dev/null 2>&1; then
    echo "npm 已安装，版本: $(npm -v)"
else
    echo "npm 未安装，正在安装..."
    sudo apt-get install -y npm
fi


# 检查并安装 PM2
if command -v pm2 > /dev/null 2>&1; then
    echo "PM2 已安装，版本: $(pm2 -v)"
else
    echo "PM2 未安装，正在安装..."
    npm install pm2@latest -g
fi


# 安装代理服务器
# 创建代理目录
rm -rf $CYSIC_AGENT_PATH
mkdir -p $CYSIC_AGENT_PATH
cd $CYSIC_AGENT_PATH

# 下载代理服务器
wget https://gitee.com/XinRunServer/aleo_-cysic/raw/master/cysic-prover-agent-v0.1.15.tgz
tar -xf cysic-prover-agent-v0.1.15.tgz
cd cysic-prover-agent-v0.1.15

# 启动代理服务器
bash start.sh
echo "代理服务器已启动。"


# 安装证明器
# 创建证明器目录
rm -rf $CYSIC_PROVER_PATH
mkdir -p $CYSIC_PROVER_PATH
cd $CYSIC_PROVER_PATH

# 下载证明器
wget https://gitee.com/XinRunServer/aleo_-cysic/raw/master/cysic-aleo-prover-v0.1.18.tgz
tar -xf cysic-aleo-prover-v0.1.18.tgz 
cd cysic-aleo-prover-v0.1.18

# # 获取用户的奖励领取地址
# read -p "请输入您的奖励领取地址 (Aleo 地址,没有的话进入 https://www.provable.tools/account 创建): " CLAIM_REWARD_ADDRESS
    
# # 获取用户的 IP 地址
# read -p "请输入代理服务器的IP地址和端口 (例如: 192.168.1.100:9000): " PROVER_IP

# 创建启动脚本
cat <<EOF > start_prover.sh
#!/bin/bash
cd $CYSIC_PROVER_PATH/cysic-aleo-prover-v0.1.18
export LD_LIBRARY_PATH=./:\$LD_LIBRARY_PATH
./cysic-aleo-prover -l ./prover.log -a 0.0.0.0:9000 -w $CLAIM_REWARD_ADDRESS.$(curl -s ifconfig.me) -tls=true -p asia.aleopool.cysic.xyz:16699
EOF

chmod +x start_prover.sh

# 使用 PM2 启动证明器
pm2 start start_prover.sh --name "cysic-aleo-prover"
echo "证明器已安装并启动。"

