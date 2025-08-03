 Dockerfile untuk aplikasi React 17.0.2 menggunakan multi-stage build

# --- Stage 1: Build Aplikasi React ---
# Menggunakan Node.js versi 17 yang ringan (alpine) untuk membangun (build) aplikasi.
FROM node:17-alpine AS builder

# Menentukan direktori kerja di dalam container.
WORKDIR /app

# Menyalin file package.json dan package-lock.json untuk menginstal dependensi.
# Langkah ini dioptimalkan untuk memanfaatkan Docker cache.
COPY package*.json ./

# Menginstal semua dependensi proyek.
RUN npm install

# Menyalin seluruh kode sumber aplikasi ke dalam direktori kerja.
COPY . .

# Membangun (build) aplikasi React untuk mode produksi.
# Hasil build akan disimpan di direktori `build`.
RUN npm run build

# --- Stage 2: Menjalankan (serve) Aplikasi Menggunakan Nginx ---
# Menggunakan Nginx yang ringan (alpine) untuk menyajikan file statis dari hasil build.
FROM nginx:alpine

# Menyalin file konfigurasi Nginx kustom.
# Ini penting untuk menangani routing Single Page Application (SPA).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Menyalin hasil build aplikasi dari stage 'builder' ke direktori Nginx.
COPY --from=builder /app/build /usr/share/nginx/html

# Mengarahkan Nginx untuk mendengarkan di port 80 secara default.
EXPOSE 80

# Perintah default untuk memulai Nginx.
CMD ["nginx", "-g", "daemon off;"]
