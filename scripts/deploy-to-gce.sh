#!/bin/bash

# ==============================================================================
# Skrip otomatis untuk men-deploy Docker image ke Google Compute Engine (GCE)
# ==============================================================================

# Variabel konfigurasi - ganti dengan nilai yang sesuai
# ------------------------------------------------------------------------------
# IP eksternal dari instance Compute Engine Anda.
GCE_IP="<IP-PUBLIK-GCE>"

# Nama pengguna (user) di GCE Anda. Defaultnya adalah nama akun Google Anda.
GCE_USER="<NAMA-USER-GCE>"

# Lokasi repositori di Google Artifact Registry.
# Format: <REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO_NAME>/<IMAGE_NAME>:<TAG>
DOCKER_IMAGE_NAME="asia-southeast2-docker.pkg.dev/<PROJECT_ID>/<REPO_NAME>/<IMAGE_NAME>:latest"

# Nama container Docker yang akan dijalankan di GCE.
CONTAINER_NAME="my-web-app"
# ------------------------------------------------------------------------------

# Fungsi untuk menampilkan pesan error dan keluar
handle_error() {
  echo "Error: $1" >&2
  exit 1
}

# Periksa apakah semua variabel telah diisi
if [ -z "$34.101.235.208" ] || [ -z "$khali" ] || [ -z "$asia-southeast2-docker.pkg.dev/fullstak-project/fullstak-repo" ]; then
  handle_error "Harap lengkapi semua variabel konfigurasi di skrip."
fi

echo "Memulai proses deployment ke GCE..."
echo "IP GCE: $GCE_IP"
echo "User GCE: $GCE_USER"
echo "Docker Image: $DOCKER_IMAGE_NAME"

# Menjalankan perintah SSH untuk deployment di GCE
ssh -o StrictHostKeyChecking=no "$GCE_USER"@"$GCE_IP" "
  set -e

  echo '>>> Mengotentikasi ke Google Artifact Registry...'
  gcloud auth configure-docker asia-southeast2-docker.pkg.dev --quiet

  echo '>>> Menarik (pull) image Docker terbaru...'
  docker pull $DOCKER_IMAGE_NAME

  echo '>>> Menghentikan dan menghapus container lama (jika ada)...'
  docker stop $CONTAINER_NAME || true
  docker rm $CONTAINER_NAME || true

  echo '>>> Menjalankan container baru...'
  docker run -d --name $CONTAINER_NAME -p 80:80 $DOCKER_IMAGE_NAME

  echo 'Deployment berhasil!'
" || handle_error "Gagal terhubung atau menjalankan perintah SSH."

echo "Proses deployment skrip selesai."
