# ====================================================================
# Tahap 1: Build Aplikasi React
# Gunakan base image Node.js yang stabil dan sesuai untuk React.
# Menggunakan Node 17-alpine adalah pilihan yang baik untuk ukuran yang ringan.
# ====================================================================
FROM node:17-alpine AS builder

# Menentukan direktori kerja di dalam container.
WORKDIR /app

# Menyalin file package.json dan package-lock.json (atau package-lock.json)
# Langkah ini penting untuk mengoptimalkan cache Docker. Jika file ini tidak berubah,
# Docker tidak akan menjalankan ulang `npm install`.
COPY package*.json ./

# Menginstal semua dependensi proyek.
# Bendera --no-cache-dir bisa ditambahkan untuk menghemat ruang, tetapi mungkin tidak selalu diperlukan.
RUN npm install

# Menyalin seluruh kode sumber aplikasi ke dalam direktori kerja.
# Langkah ini dilakukan setelah `npm install` untuk memaksimalkan efisiensi cache.
COPY . .

# Membangun (build) aplikasi React untuk mode produksi.
# Hasil build akan disimpan di direktori `/app/build`.
RUN npm run build

# ====================================================================
# Tahap 2: Menjalankan (serve) Aplikasi Menggunakan Nginx dan Prometheus Exporter
# Gunakan base image Nginx yang sangat ringan untuk lingkungan produksi.
# ====================================================================
FROM nginx:alpine

# Menambahkan Prometheus Nginx Exporter dari GitHub
# `apk add` digunakan untuk menginstal curl di Alpine Linux.
# Curl akan mengunduh tar.gz, lalu `tar xz` mengekstraknya.
# Prometheus Exporter dipindahkan ke `/usr/local/bin/` agar dapat dieksekusi.
RUN apk add --no-cache curl \
    && curl -sL https://github.com/nginxinc/nginx-prometheus-exporter/releases/download/v0.11.0/nginx-prometheus-exporter_0.11.0_linux_amd64.tar.gz | tar xz \
    && mv nginx-prometheus-exporter /usr/local/bin/

# Menyalin file konfigurasi Nginx kustom dan skrip startup.
# Asumsi file-file ini ada di direktori yang sama dengan Dockerfile.
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY run.sh /run.sh

# Memberikan izin eksekusi pada skrip startup.
RUN chmod +x /run.sh

# Menyalin hasil build aplikasi dari tahap 'builder' ke direktori Nginx.
# /usr/share/nginx/html adalah direktori default Nginx untuk file web.
COPY --from=builder /app/build /usr/share/nginx/html

# Mengarahkan Nginx untuk mendengarkan di port 80 (untuk aplikasi)
# dan exporter di port 9113 (untuk metrik Prometheus).
EXPOSE 80
EXPOSE 9113


# Menginstal Grafana secara manual
RUN apk add --no-cache bash libc6-compat \
    && wget https://dl.grafana.com/oss/release/grafana-10.2.3.linux-amd64.tar.gz \
    && tar -zxvf grafana-10.2.3.linux-amd64.tar.gz \
    && mv grafana-10.2.3 /opt/grafana \
    && rm grafana-10.2.3.linux-amd64.tar.gz

# Perintah untuk menjalankan skrip yang memulai Nginx dan Exporter.
# Skrip ini memastikan kedua layanan berjalan di satu container.
CMD ["/run.sh"]
