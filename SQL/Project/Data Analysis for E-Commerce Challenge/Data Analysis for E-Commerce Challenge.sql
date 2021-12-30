use dqlab_ecommerce;

-- 10 Transaksi terbesar user 12476

select seller_id, buyer_id, total as nilai_transaksi, created_at as tanggal_transaksi
from orders
where buyer_id = 12476
order by 3 desc
limit 10;

-- Transaksi per bulan

select extract(year_month from created_at) as tahun_bulan, count(1) as jumlah_transaksi, sum(total) as total_nilai_transaksi
from orders
where created_at>='2020-01-01'
group by 1
order by 1;

-- Pengguna dengan rata-rata transaksi terbesar di Januari 2020

select buyer_id, count(1) as jumlah_transaksi, avg(total) as avg_nilai_transaksi
from orders
where created_at>='2020-01-01' and created_at<'2020-02-01'
group by 1
having count(1)>= 2 
order by 3 desc
limit 10;

-- Transaksi besar di Desember 2019

select nama_user as nama_pembeli, total as nilai_transaksi, created_at as tanggal_transaksi
from orders
inner join users on buyer_id = user_id
where created_at>='2019-12-01' and created_at<'2020-01-01'
and total >= 20000000
order by 1;

-- Kategori Produk Terlaris di 2020

select category, sum(quantity) as total_quantity, sum(price) as total_price
from orders
inner join order_details using(order_id)
inner join products using(product_id)
where created_at>='2020-01-01'
and delivery_at is not null
group by 1
order by 2 desc
limit 5;

-- Mencari pembeli high value

select nama_user as nama_pembeli, count(1) as jumlah_transaksi, sum(total) as total_nilai_transaksi, min(total) as min_nilai_transaksi
from orders
inner join users on buyer_id = user_id
group by user_id, nama_user
having count(1) > 5 and min(total)>2000000
order by 3 desc;

-- Mencari Dropshipper

select nama_user as nama_pembeli, count(1) as jumlah_transaksi, count(distinct orders.kodepos) as distinct_kodepos, sum(total) as total_nilai_transaksi, avg(total) as avg_nilai_transaksi 
from orders
inner join users on buyer_id = user_id
group by user_id, nama_user
having count(1) >= 10 and count(1)=count(distinct orders.kodepos) 
order by 2 desc;

-- Mencari Reseller Offline

select nama_user as nama_pembeli, count(1) as jumlah_transaksi, sum(total) as total_nilai_transaksi, avg(total) as avg_nilai_transaksi, avg(total_quantity) as avg_quantity_per_transaksi
from orders
inner join users on buyer_id=user_id
inner join (
  			select order_id, 
  				   sum(quantity) as total_quantity
  			from order_details
			group by 1
  			) as summary_order using (order_id)
where orders.kodepos=users.kodepos
group by user_id, nama_user
having count(1) >= 8 and avg(total_quantity)>10
order by 3 desc;

-- Pembeli sekaligus penjual

select nama_user as nama_pengguna, jumlah_transaksi_beli, jumlah_transaksi_jual
from users
inner join (
			select buyer_id, 
  			count(1) as jumlah_transaksi_beli
  			from orders
  			group by 1
            ) as buyer
on buyer_id = user_id
inner join (
  			select seller_id,
  			count(1) as jumlah_transaksi_jual
  			from orders
  			group by 1
  			) as seller
on seller_id = user_id
where jumlah_transaksi_beli >= 7
order by 1;

-- Lama transaksi dibayar

select 
	extract(year_month from created_at) as tahun_bulan, 
	count(1) as jumlah_transaksi,
	avg(datediff(paid_at, created_at)) as avg_lama_dibayar,
	min(datediff(paid_at, created_at)) min_lama_dibayar,
	max(datediff(paid_at, created_at)) max_lama_dibayar
from orders
where paid_at is not null
group by 1
order by 1;