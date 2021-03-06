# -*- coding: utf-8 -*-
"""Simple ETL with Pandas.ipynb

Automatically generated by Colaboratory.

Original file is located at
    https://colab.research.google.com/drive/15qjqmUMDMDuKL1C6wKM-PH4owA9GYAJu

#Simple ETL with Pandas
Extract, Transform dan Load (ETL) merupakan kumpulan proses untuk "memindahkan" data dari satu tempat ke tempat lain, yaitu dari sumber data (bisa berupa database aplikasi, file, logs, database dari 3rd party, dan lainnya) ke data warehouse.
"""

#Extract
import pandas as pd
df_participant = pd.read_csv('https://storage.googleapis.com/dqlab-dataset/dqthon-participants.csv')

print(df_participant.shape)
print(df_participant.info())
print(df_participant.head())

"""#####Transform
* Merubah nilai dari suatu kolom ke nilai baru,
* Menciptakan kolom baru dengan memanfaatkan kolom lain,
* Transpose baris menjadi kolom (atau sebaliknya),
* Mengubah format data ke bentuk yang lebih standard (contohnya, kolom date maupun datetime yang biasanya memiliki nilai yang tidak standard maupun nomor * HP yang biasanya memiliki nilai yang tidak sesuai format standardnya), dan lainnya. 

"""

print(df_participant['address'].head())

#Transform Bagian I - Kode Pos
df_participant['postal_code'] = df_participant['address'].str.extract(r'(\d+)$') #Masukkan regex didalam fungsi extract
print(df_participant['postal_code'].head())

#Transform Bagian II - Kota
#Masukkan regex didalam fungsi extract
df_participant['city'] = df_participant['address'].str.extract(r'(?<=\n)(\w.+)(?=,)')
print(df_participant['city'].head())

print(df_participant[['first_name', 'last_name']].head())
#Transform Bagian III - Github
df_participant['github_profile'] = 'https://github.com/' + df_participant['first_name'].str.lower() + df_participant['last_name'].str.lower()
print(df_participant['github_profile'].head())

#Transform Bagian IV - Nomor Handphone
#Jika awalan nomor HP berupa angka 62 atau +62 yang merupakan kode telepon Indonesia, maka diterjemahkan ke 0.
#Tidak ada tanda baca seperti kurung buka, kurung tutup, strip⟶ ()-
#Tidak ada spasi pada nomor HP nama kolom untuk menyimpan hasil cleansing pada nomor HP yaitu cleaned_phone_number
print(df_participant['phone_number'].head())
#Masukkan regex pada parameter pertama dari fungsi replace
df_participant['cleaned_phone_number'] = df_participant['phone_number'].str.replace(r'^(\+62|62)', '0')
df_participant['cleaned_phone_number'] = df_participant['cleaned_phone_number'].str.replace(r'[()-]', '')
df_participant['cleaned_phone_number'] = df_participant['cleaned_phone_number'].str.replace(r'\s+', '')

print(df_participant['cleaned_phone_number'].head())

print(df_participant[['first_name','last_name','country','institute']].head())

#Transform Bagian V - Nama Tim
def func(col):
    abbrev_name = "%s%s"%(col['first_name'][0],col['last_name'][0]) #Singkatan dari Nama Depan dan Nama Belakang dengan mengambil huruf pertama
    country = col['country']
    abbrev_institute = '%s'%(''.join(list(map(lambda word: word[0], col['institute'].split())))) #Singkatan dari value di kolom institute
    return "%s-%s-%s"%(abbrev_name,country,abbrev_institute)

df_participant['team_name'] = df_participant.apply(func, axis=1)
print(df_participant['team_name'].head())

#Transform Bagian VI - Email
def func(col):
    first_name_lower = col['first_name'].lower()
    last_name_lower = col['last_name'].lower()
    institute = ''.join(list(map(lambda word: word[0], col['institute'].lower().split()))) #Singkatan dari nama perusahaan dalam lowercase

    if 'Universitas' in col['institute']:
        if len(col['country'].split()) > 1: #Kondisi untuk mengecek apakah jumlah kata dari country lebih dari 1
            country = ''.join(list(map(lambda word: word[0], col['country'].lower().split())))
        else:
            country = col['country'][:3].lower()
        return "%s%s@%s.ac.%s"%(first_name_lower,last_name_lower,institute,country)

    return "%s%s@%s.com"%(first_name_lower,last_name_lower,institute)

df_participant['email'] = df_participant.apply(func, axis=1)
print(df_participant['email'].head())

# Transform Bagian VII - Tanggal Lahir
df_participant['birth_date'] = pd.to_datetime(df_participant['birth_date'], format='%d %b %Y')
print(df_participant['birth_date'].head())

#Transform Bagian VII - Tanggal Daftar Kompetisi
df_participant['register_at'] = pd.to_datetime(df_participant['register_time'], unit='s')
print(df_participant['register_time'].head())

print(df_participant.info())

"""Dari data kolom sebelumnya saat proses extract, ada beberapa kolom tambahan yang didapatkan dengan memanfaatkan kolom. Saat ini dataset memuat 16 kolom."""