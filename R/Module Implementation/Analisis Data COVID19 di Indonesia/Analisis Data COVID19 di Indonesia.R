#Analisis data covid19 di Indonesia
#Mengakses API covid.go.id
library(httr)
set_config(config(ssl_verifypeer = 0L))
resp <- GET ("https://data.covid19.go.id/public/api/update.json")

#Status Code
status_code (resp)
#200: permintaan sukses dipenuhi.

#Status Code - 2
resp$status_code
identical(resp$status_code, status_code(resp))

#Headers API
headers(resp)

#Mengekstrak isi Respon
cov_id_raw <- content(resp, as = "parsed", simplifyVector = TRUE) 

#Mengekstrak isi Respon - Pt 2
length(cov_id_raw)
names(cov_id_raw)
cov_id_update <- cov_id_raw$update

#Analisa Data
lapply(cov_id_update,names)
cov_id_update$penambahan$tanggal
cov_id_update$penambahan$jumlah_sembuh
cov_id_update$penambahan$jumlah_meninggal
cov_id_update$total$jumlah_positif
cov_id_update$total$jumlah_meninggal

#COVID-19 Di Sekitar
#Apa Kabar Jawa Barat?
library(httr)
set_config(config(ssl_verifypeer = 0L))
resp_jabar <- GET("https://data.covid19.go.id/public/api/prov_detail_JAWA_BARAT.json")
cov_jabar_raw <- content(resp_jabar, as = "parsed", simplifyVector = TRUE)


names(cov_jabar_raw)
cov_jabar_raw$kasus_total
cov_jabar_raw$meninggal_persen
cov_jabar_raw$sembuh_persen

#Memperoleh Informasi yang Lebih Lengkap
cov_jabar <- cov_jabar_raw$list_perkembangan
str(cov_jabar)
head(cov_jabar)

#Menjinakkan Data
library(dplyr)
new_cov_jabar <-
  cov_jabar %>% 
  select(-contains("DIRAWAT_OR_ISOLASI")) %>% 
  select(-starts_with("AKUMULASI")) %>% 
  rename(
    kasus_baru = KASUS,
    meninggal = MENINGGAL,
    sembuh = SEMBUH
  ) %>% 
  mutate(
    tanggal = as.POSIXct(tanggal / 1000, origin = "1970-01-01"),
    tanggal = as.Date(tanggal)
  )
str(new_cov_jabar)

#Menunjukkan Melalui Gambar
library(ggplot2)
library(hrbrthemes)
ggplot(new_cov_jabar, aes(x = tanggal, y = kasus_baru)) +
  geom_col()

#Menunjukkan Melalui Gambar - Pt 2
ggplot(new_cov_jabar, aes(tanggal, kasus_baru)) +
  geom_col(fill = "salmon") + 
  labs(
    x = NULL, 
    y = "Jumlah kasus",
    title = "Kasus Harian Positif COVID-19 di Jawa Barat", 
    subtitle = "Terjadi pelonjakan kasus di awal bulan Juli akibat klaster Secapa AD Bandung", 
    caption = "Sumber data: covid.19.go.id"
  ) + 
  theme_ipsum(
    base_size = 13, 
    plot_title_size = 21, 
    grid = "Y", 
    ticks = TRUE
  ) + 
  theme(plot.title.position = "plot")

#Grafik untuk Kasus Sembuh
ggplot(new_cov_jabar, aes(tanggal, sembuh)) +
  geom_col(fill = "olivedrab2") +
  labs(
    x = NULL,
    y = "Jumlah kasus",
    title = "Kasus Harian Sembuh Dari COVID-19 di Jawa Barat",
    caption = "Sumber data: covid.19.go.id"
  ) +
  theme_ipsum(
    base_size = 13, 
    plot_title_size = 21,
    grid = "Y",
    ticks = TRUE
  ) +
  theme(plot.title.position = "plot")

#Grafik untuk Kasus Meninggal
ggplot(new_cov_jabar, aes(tanggal, meninggal)) +
  geom_col(fill = "darkslategray4") +
  labs(
    x = NULL,
    y = "Jumlah kasus",
    title = "Kasus Harian Meninggal Akibat COVID-19 di Jawa Barat",
    caption = "Sumber data: covid.19.go.id"
  ) +
  theme_ipsum(
    base_size = 13, 
    plot_title_size = 21,
    grid = "Y",
    ticks = TRUE
  ) +
  theme(plot.title.position = "plot")

#Apakah Pekan ini Lebih Baik?
library(dplyr)
library(lubridate)

cov_jabar_pekanan <- new_cov_jabar %>% 
  count(
    tahun = year(tanggal),
    pekan_ke = week(tanggal),
    wt = kasus_baru,
    name = "jumlah"
  )

glimpse(cov_jabar_pekanan)

#Menjawab Pertanyaan
library(dplyr)
cov_jabar_pekanan <-
  cov_jabar_pekanan %>% 
  mutate(
    jumlah_pekanlalu = dplyr::lag(jumlah, 1),
    jumlah_pekanlalu = ifelse(is.na(jumlah_pekanlalu), 0, jumlah_pekanlalu),
    lebih_baik = jumlah < jumlah_pekanlalu
  )
glimpse(cov_jabar_pekanan)

#Membuat Bar Chart
library(ggplot2)
library(hrbrthemes)
ggplot(cov_jabar_pekanan[cov_jabar_pekanan$tahun==2020,], aes(pekan_ke, jumlah, fill = lebih_baik)) +
  geom_col(show.legend = FALSE) + 
  scale_x_continuous(breaks = 9:29, expand = c(0, 0)) +
  scale_fill_manual(values = c("TRUE" = "seagreen3", "FALSE" = "salmon")) +
  labs(
    x = NULL,
    y = "Jumlah kasus", 
    title = "Kasus Pekanan Positif COVID-19 di Jawa Barat", 
    subtitle = "Kolom hijau menunjukan penambahan kasus baru lebih sedikit dibandingkan satu pekan sebelumnya",
    caption = "Sumber data: covid.19.go.id"
  ) + 
  theme_ipsum(
    base_size = 13, 
    plot_title_size = 21,
    grid = "Y",
    ticks = TRUE
  ) + 
  theme(plot.title.position = "plot")

#Pola dan Dinamika
library(dplyr)
cov_jabar_akumulasi <- 
  new_cov_jabar %>% 
  transmute(
    tanggal,
    akumulasi_aktif = cumsum(kasus_baru) - cumsum(sembuh) - cumsum(meninggal),
    akumulasi_sembuh = cumsum(sembuh),
    akumulasi_meninggal = cumsum(meninggal)
  )

tail(cov_jabar_akumulasi)

#Membuat Line Chart
library(ggplot2)
ggplot(data = cov_jabar_akumulasi, aes(x = tanggal, y = akumulasi_aktif)) +
  geom_line()

#Transformasi Data
library(dplyr)
library(tidyr)

dim(cov_jabar_akumulasi)

cov_jabar_akumulasi_pivot <- 
  cov_jabar_akumulasi %>% 
  gather(
    key = "kategori",
    value = "jumlah",
    -tanggal
  ) %>% 
  mutate(
    kategori = sub(pattern = "akumulasi_", replacement = "", kategori)
  )

dim(cov_jabar_akumulasi_pivot)

glimpse(cov_jabar_akumulasi_pivot)

#Tahap Terakhir
library(ggplot2)
library(hrbrthemes)
ggplot(cov_jabar_akumulasi_pivot, aes(tanggal, jumlah, colour = (kategori))) +
  geom_line(size = 0.9) +
  scale_y_continuous(sec.axis = dup_axis(name = NULL)) +
  scale_colour_manual(
    values = c(
      "aktif" = "salmon",
      "meninggal" = "darkslategray4",
      "sembuh" = "olivedrab2"
    ),
    labels = c("Aktif", "Meninggal", "Sembuh")
  ) + 
  labs(
    x = NULL,
    y = "Jumlah kasus akumulasi", 
    colour = NULL, 
    title = "Dinamika Kasus COVID-19 di Jawa Barat", 
    caption = "Sumber data: covid.19.go.id"
  ) + 
  theme_ipsum(
    base_size = 13, 
    plot_title_size = 21, 
    grid = "Y", 
    ticks = TRUE
  ) + 
  theme(
    plot.title = element_text(hjust = 0.5),
    legend.position = "top"
  )

