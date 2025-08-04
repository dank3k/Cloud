# ====================================================================
# Tahap 1: Build Aplikasi React
# Gunakan base image Node.js yang stabil dan sesuai untuk React.
# Menggunakan Node 17-alpine adalah pilihan yang baik untuk ukuran yang ringan.
# ====================================================================
FROM node:17-alpine AS builder

# Menentukan direktori kerja di dalam container.
WORKDIR /app

# Menyalin file package.json dan package-lock.json.
# Langkah ini penting untuk mengoptimalkan cache Docker.
COPY package*.json ./

# Menginstal semua dependensi proyek.
RUN npm install

# Menyalin seluruh kode sumber aplikasi ke dalam direktori kerja.
COPY . .

# Membangun (build) aplikasi React untuk mode produksi.
RUN npm run build

# ====================================================================
# Tahap 2: Menjalankan (serve) Aplikasi Menggunakan Nginx dan Prometheus Exporter
# Gunakan base image Nginx yang sangat ringan untuk lingkungan produksi.
# ====================================================================
FROM nginx:alpine

# Menambahkan Prometheus Nginx Exporter dari GitHub
RUN apk add --no-cache curl \
    && curl -sL https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz | tar xz \
    && mv nginx-prometheus-exporter /usr/local/bin/

# ====================================================================
# File Konfigurasi Nginx: nginx.conf
# ====================================================================
# Konfigurasi ini memastikan semua rute (route) dilayani oleh index.html,
# yang esensial untuk aplikasi Single Page Application (SPA).
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
  listen 80;
  server_name localhost;

  location / {
    root /usr/share/nginx/html;
    index index.html index.htm;
    try_files \$uri /index.html;
  }

  # Konfigurasi status Nginx untuk Prometheus Exporter
  location /nginx_status {
    stub_status on;
    allow 127.0.0.1; # Hanya izinkan dari localhost
    deny all;
  }
}
EOF

# ====================================================================
# Skrip Startup: run.sh
# ====================================================================
# Skrip ini menjalankan Prometheus Exporter di background dan Nginx di foreground.
# Ini memastikan kedua proses berjalan dalam satu container.
COPY <<EOF /run.sh
#!/bin/sh

# Jalankan Prometheus Exporter di background
/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri http://127.0.0.1/nginx_status &

# Jalankan Nginx di foreground
nginx -g "daemon off;"
EOF

# Memberikan izin eksekusi pada skrip startup.
RUN chmod +x /run.sh

# Menyalin hasil build aplikasi dari tahap 'builder' ke direktori Nginx.
COPY --from=builder /app/build /usr/share/nginx/html

# Mengarahkan Nginx untuk mendengarkan di port 80 (untuk aplikasi)
# dan exporter di port 9113 (untuk metrik Prometheus).
EXPOSE 80
EXPOSE 9113

# Perintah untuk menjalankan skrip yang memulai Nginx dan Exporter.
CMD ["/run.sh"]
