# Dataset Kriminalitas Polda 2019–2024

## Status kompilasi
File `crime_total_polda_2019_2024.csv` berisi 204 observasi: 34 yurisdiksi Polda × 6 tahun (2019–2024). Unit geografis pada seri ini adalah yurisdiksi Polda, bukan 38 provinsi administratif yang telah diharmonisasi.

## Variabel
- `year`: tahun kejadian.
- `region`: yurisdiksi Polda sebagaimana tabel sumber.
- `crime_type`: Semua kejahatan (crime total).
- `incidents`: jumlah kejahatan yang dilaporkan.
- `population`: denominator populasi; sengaja kosong dalam kompilasi ini.
- `crime_rate_official`: crime rate resmi BPS per 100.000 penduduk, tersedia untuk 2022–2024.
- `clearance_rate_official`: persentase penyelesaian kejahatan resmi BPS, tersedia untuk 2022–2024.
- `source`: publikasi dan tabel sumber.

## Sumber dan cakupan
1. **2019–2020:** seri tabel BPS Statistik Kriminal 2021, registrasi Kepolisian menurut Polda.
   - https://www.bps.go.id/id/publication/2021/12/15/8d1bc84d2055e99feed39986/crime-statistics-2021.html
2. **2021:** BPS Statistik Kriminal 2023, Lampiran 3, jumlah kejahatan menurut Polda 2020–2022.
   - https://internet.contenidos.inegi.org.mx/contenidos/unodc/doc/atlas/asia/indonesia/2023/Indonesia_%20statistik_kriminal_2023.pdf
3. **2022–2024:** BPS Statistik Indonesia 2026, Tabel 4.4.1, halaman cetak 302–304. Tabel menyajikan crime total, crime rate per 100.000 penduduk, clearance rate, dan crime clock menurut Polda.
   - Publikasi BPS: https://www.bps.go.id/id/publication/2026/02/27/a43f03f45543dc4e9942f44c/statistik-indonesia-2026.html
   - Salinan publikasi yang dapat dibaca: https://seadelt.net/Asset/Source/Document_ID-557_No-01.pdf

## Catatan metodologis penting
1. Tabel BPS 2026 menyediakan 34 baris yurisdiksi Polda yang memiliki angka untuk 2022–2024. Empat provinsi baru di Papua ditampilkan dengan tanda “–”; tanda tersebut adalah data tidak tersedia/tidak disajikan, bukan nol kejadian.
2. Nama Metro Jaya adalah yurisdiksi Polda dan tidak identik dengan Provinsi DKI Jakarta dalam semua definisi wilayah. Karena itu, jangan langsung melabeli seluruh baris Polda sebagai provinsi tanpa catatan batas cakupan.
3. Untuk 2022, angka BPS 2026 memperbarui seri yang sebelumnya dikompilasi dari publikasi lebih lama. Dataset ini memakai angka BPS 2026 untuk 2022–2024.
4. Kolom populasi tetap kosong. Crime rate resmi BPS disimpan sebagai variabel tersendiri dan tidak dihitung ulang dari populasi yang tidak tersedia.
5. Grafik dashboard yang menampilkan rata-rata aritmetis crime rate antar-Polda bukan crime rate nasional tertimbang. Crime rate nasional resmi BPS tahun 2024 adalah 204 per 100.000 penduduk, sedangkan tabel Polda menyajikan angka masing-masing yurisdiksi.
6. Clearance rate bukan tingkat penghukuman atau conviction rate. Interpretasikan sesuai definisi statistik Kepolisian/BPS dan periksa bahwa nilainya dapat melebihi 100 pada wilayah/tahun tertentu.
7. Seri 2019–2021 berasal dari publikasi BPS yang lebih lama, sedangkan 2022–2024 menggunakan Tabel 4.4.1 BPS 2026. Perubahan metode, pencatatan, dan cakupan harus diperhatikan saat menafsirkan perubahan antarwaktu.
8. Seri 2025 belum ditambahkan karena belum ditemukan tabel registrasi kriminalitas Polda 2025 yang setara dan terverifikasi dalam sumber yang digunakan pada pembaruan ini.
9. Data kabupaten/kota belum ditambahkan. Penambahan harus memakai publikasi BPS daerah/Polres yang jelas unit, cakupan, dan tahunnya; jangan mengalokasikan angka Polda ke kabupaten/kota.

## Interpretasi
- Crime total mengukur kejadian yang tercatat/dilaporkan dalam registrasi Kepolisian, bukan seluruh kejadian kriminal yang dialami masyarakat.
- Crime rate adalah jumlah kejahatan setahun dibagi jumlah penduduk tahun yang bersangkutan × 100.000.
- Clearance rate adalah indikator penyelesaian kejahatan menurut definisi sumber; bukan ukuran langsung efektivitas penuntutan atau putusan pengadilan.
- Survei korban Susenas dan indikator kewilayahan Podes merupakan seri berbeda dan tidak boleh digabungkan dengan crime total registrasi Kepolisian.
