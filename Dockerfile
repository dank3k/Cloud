# ====================================================================
# Tahap 1: Build Aplikasi React
# Menggunakan Node.js yang ringan sebagai base image untuk membangun aplikasi.
# ====================================================================
FROM node:17-alpine AS builder

# Atur direktori kerja di dalam container.
WORKDIR /app

# Salin file package.json untuk menginstal dependensi.
COPY package*.json ./

# Instal semua dependensi proyek.
RUN npm install

# Salin seluruh kode sumber aplikasi.
COPY . .

# Bangun aplikasi React untuk mode produksi.
RUN npm run build

# ====================================================================
# Tahap 2: Menjalankan Aplikasi Menggunakan Nginx dan Prometheus Exporter
# Menggunakan Nginx yang ringan sebagai base image.
# ====================================================================
FROM nginx:alpine

# Pasang curl untuk mengunduh Prometheus Exporter.
RUN apk add --no-cache curl \
    && curl -sL https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz | tar xz \
    && mv nginx-prometheus-exporter /usr/local/bin/

# Salin file konfigurasi Nginx dan skrip startup.
# Pastikan file-file ini ada di direktori yang sama dengan Dockerfile.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

# Beri izin eksekusi pada skrip startup.
RUN chmod +x /run.sh

# Salin hasil build aplikasi dari tahap 'builder' ke direktori Nginx.
COPY --from=builder /app/build /usr/share/nginx/html

# Ekspos port 80 untuk aplikasi dan port 9113 untuk Prometheus Exporter.
EXPOSE 80
EXPOSE 9113

# Perintah untuk menjalankan skrip yang memulai Nginx dan Exporter.
CMD ["/run.sh"]
