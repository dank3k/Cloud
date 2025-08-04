#!/bin/sh

# Jalankan Nginx di background
# `daemon off;` mencegah Nginx keluar setelah startup
# dan `&` mengirimnya ke background
nginx -g 'daemon off;' &

# Jalankan Nginx Prometheus Exporter di background
# Exporter mengambil metrik dari endpoint status Nginx
/usr/local/bin/nginx-prometheus-exporter -nginx.scrape-uri=http://127.0.0.1/stub_status &

# Perintah `wait -n` akan menunggu salah satu proses di atas selesai.
# Ini mencegah container keluar jika salah satu layanan crash.
wait -n

# Keluar dengan kode status dari proses yang selesai pertama kali
exit $?
