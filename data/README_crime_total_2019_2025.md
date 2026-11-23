# Dataset Kriminalitas Polda 2019–2022

## Status
Dataset awal ini berisi 136 observasi (34 yurisdiksi Polda × 4 tahun) berupa jumlah kejahatan tercatat (*crime total*). Dashboard memuatnya otomatis sebagai seri awal.

## Sumber
- 2019: BPS, tabel statistik "Jumlah Kejahatan yang Dilaporkan ... Menurut Kepolisian Daerah, 2019", sumber data Mabes Polri (Biro Pengendalian Operasi). https://www.bps.go.id/id/statistics-table/3/VlVneFlXOVJOSFpNUzNKcU4zVlFla2syVEZjd1VUMDkjMyMwMDAw/jumlah-kejahatan-yang-dilaporkan-risiko-penduduk-terkena-kejahatan-per-100-000-penduduk-persentase-penyelesaian-kejahatan-dan-selang-waktu-terjadinya-kejahatan-menurut-provinsi.html?year=2019
- 2020: BPS, Statistik Kriminal 2021, tabel 2.1.3 "Jumlah Kejahatan Menurut Kepolisian Daerah, 2018–2020". https://www.bps.go.id/id/publication/2021/12/15/8d1bc84d2055e99feed39986/crime-statistics-2021.html
- 2021–2022: BPS, Statistik Kriminal 2023, Lampiran 3 "Jumlah Kejahatan Menurut Kepolisian Daerah, 2020–2022", sumber Biro Pengendalian Operasi, Mabes Polri. https://internet.contenidos.inegi.org.mx/contenidos/unodc/doc/atlas/asia/indonesia/2023/Indonesia_%20statistik_kriminal_2023.pdf

## Batasan penting
1. Kolom `region` memakai nama yurisdiksi Polda, bukan unit provinsi yang sudah diharmonisasi.
2. Seri ini berisi 34 yurisdiksi Polda sesuai struktur dan cakupan sumber pada periode tersebut. Empat provinsi baru di Papua tidak boleh dibuat sebagai observasi terpisah untuk tahun sebelum pemekaran tanpa data resmi.
3. Untuk 2022, BPS mencatat total nasional 372.965 termasuk 68 kejadian yang dilaporkan melalui Mabes Polri. Tabel 34 Polda pada file ini tidak memasukkan baris Mabes Polri, sehingga jumlah 34 Polda tidak persis sama dengan total nasional.
4. Kolom `population` sengaja dikosongkan. Crime rate tidak boleh dihitung dari populasi tebakan atau hasil pembagian terbalik atas angka rate yang telah dibulatkan. Tambahkan denominator penduduk yang sepadan setelah diverifikasi dari BPS.
5. Seri 2023–2025 belum dimasukkan. Tahun 2025 belum tersedia sebagai tahun kejadian dalam publikasi nasional BPS 2024/2025 yang menjadi rujukan saat penyusunan tahap ini. Data tingkat kabupaten/kota memerlukan kompilasi terpisah dari publikasi BPS provinsi dan harus menyertakan cakupan Polres serta catatan perubahan wilayah.
6. Jangan mencampur *crime total* registrasi Polri dengan persentase korban Susenas atau data kewilayahan Podes. Ketiganya merupakan pendekatan dan unit pengukuran berbeda.

## Skema CSV
`year,region,crime_type,incidents,population,source`

- `incidents`: jumlah kejadian tercatat.
- `population`: denominator penduduk untuk menghitung crime rate; kosong sampai tersedia angka resmi yang cocok.
- `source`: publikasi dan seri sumber.

Dataset ini adalah tahap awal yang bersumber dari tabel publikasi, bukan seri 38 provinsi yang sudah selesai diharmonisasi.
