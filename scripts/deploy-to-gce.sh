#!/bin/bash

# ==============================================================================
# Skrip otomatis untuk men-deploy Docker image ke Google Compute Engine (GCE)
# ==============================================================================

# Variabel konfigurasi
# ------------------------------------------------------------------------------
# IP eksternal dari instance Compute Engine Anda.
GCE_IP="34.101.235.208"

# Nama pengguna (user) di GCE Anda.
GCE_USER="khali"

# Lokasi repositori di Google Artifact Registry dan nama image.
DOCKER_IMAGE_NAME="asia-southeast2-docker.pkg.dev/fullstak-project/fullstak-repo/cloud-app:latest"

# Nama container Docker yang akan dijalankan di GCE.
CONTAINER_NAME="fullstak-app"
# ------------------------------------------------------------------------------

# Fungsi untuk menampilkan pesan error dan keluar
handle_error() {
  echo "Error: $1" >&2
  exit 1
}

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
