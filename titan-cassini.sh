#!/bin/bash 
# Periksa apakah skrip dijalankan sebagai pengguna root 
if [ "$(id -u)" != "0" ]; then
    echo "Skrip ini harus dijalankan dengan izin pengguna root."
    echo "Silakan coba gunakan perintah 'Gunakan sudo -i' untuk beralih ke pengguna root, lalu jalankan skrip ini lagi."
    exit 1
fi

echo "=======================Titan Node=======================" 

echo "███████╗██╗  ██╗ █████╗ ██████╗ ███████╗    ██╗████████╗    ██╗  ██╗██╗   ██╗██████╗ "
echo "██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝    ██║╚══██╔══╝    ██║  ██║██║   ██║██╔══██╗"
echo "███████╗███████║███████║██████╔╝█████╗      ██║   ██║       ███████║██║   ██║██████╔╝"
echo "╚════██║██╔══██║██╔══██║██╔══██╗██╔══╝      ██║   ██║       ██╔══██║██║   ██║██╔══██╗"
echo "███████║██║  ██║██║  ██║██║  ██║███████╗    ██║   ██║       ██║  ██║╚██████╔╝██████╔╝"
echo "╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝    ╚═╝   ╚═╝       ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ "
echo ""
echo "𝘋𝘰𝘯'𝘵 𝘧𝘰𝘳𝘨𝘦𝘵 𝘵𝘰 𝘫𝘰𝘪𝘯 𝘰𝘶𝘳 𝘰𝘧𝘧𝘪𝘤𝘪𝘢𝘭 𝘤𝘩𝘢𝘯𝘯𝘦𝘭:"
echo "Telegram: https://t.me/SHAREITHUB_COM"
echo "Youtube: https://www.youtube.com/@SHAREITHUB_COM"
echo "Repo Github: https://github.com/shareithub/"

read -p "Masukkan kode identitas anda: " id

# Biarkan pengguna memasukkan jumlah container yang ingin dibuat 
read -p "Silakan masukkan jumlah node yang ingin dibuat. Satu IP dibatasi maksimal 5 node: " container_count

# Biarkan pengguna memasukkan batas ukuran hard disk setiap node (dalam GB) 
read -p "Silakan masukkan batas ukuran hard disk setiap node (dalam GB, misalnya: 1 mewakili 1GB, 2 mewakili 2GB) : " disk_size_gb 

# Tanyakan direktori penyimpanan volume data pengguna, dan tetapkan nilai default 
read -p "Silahkan masukkan direktori penyimpanan volume data [default: /mnt/docker_volumes]: " volume_dir
volume_dir=${volume_dir:-/mnt/docker_volumes}

apt update

# Periksa apakah Docker telah diinstal Instal 
if ! command -v docker &> /dev/null
then
    echo "Docker tidak terdeteksi, sedang menginstal. .."
    apt-get install ca-certificates curl gnupg lsb-release
    
    # Instal versi terbaru Docker 
    apt-get install docker.io -y
else
    echo "Docker telah diinstal."
fi

# Tarik gambar Docker 
docker pull nezha123/titan-edge

# Buat direktori penyimpanan file gambar 
mkdir -p $volume_dir

# Buat jumlah container yang ditentukan pengguna 
for i in $(seq 1 $container_count)
do
    disk_size_mb=$((disk_size_gb * 1024))
    
    # Buat sistem file gambar dengan ukuran tertentu untuk setiap kontainer 
    volume_path="$volume_dir/volume_$i.img"
    sudo dd if=/dev/zero of=$volume_path bs=1M count=$disk_size_mb
    sudo mkfs.ext4 $volume_path

    # Buat direktori dan pasang sistem berkas 
    mount_point="/mnt/my_volume_$i"
    mkdir -p $mount_point
    sudo mount -o loop $volume_path $mount_point

    # Akan dipasang Tambahkan informasi ke /etc/fstab 
    echo "$volume_path $mount_point ext4 loop,defaults 0 0" | sudo tee -a /etc/fstab

    # Jalankan container dan setel kebijakan mulai ulang ke selalu 
    container_id=$(docker run -d --restart always -v $mount_point:/root/.titanedge/storage --name "titan$i" nezha123/titan-edge)

    echo "node titan$i telah memulai ID containe $container_id"

    sleep 30
    
    # Masuk ke container dan lakukan pengikatan dan perintah lainnya 
    docker exec -it $container_id bash -c "\
        titan-edge bind --hash=$id https://api-test1.container1.titannet.io/api/v2/device/binding"
done

echo "==============================Semua node sudah diatur dan dimulai===================================."
