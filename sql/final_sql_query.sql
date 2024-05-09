-- create table if not exists usd_rate as (
-- 	currency TEXT,
-- 	date timestamp,
-- 	usd_rate double precision
-- );

create or replace view view_ng_site_offramp_transaction as (
	
with ng_site as (
	select
	country_code
	, currency
	from public.site_countries
	where name = 'Nigeria'
)
, limit_orders_ as (
	select 
	user_id
	,'limit_order_' || l.id transaction_id
	,'limit_order' transaction_type
	,created_at
	,filled_at
	,updated_at
	,source_coin
	,filled_source_amount source_amount
	,price_currency fiat_currency
	,filled_destination_amount fiat_amount
	from public.limit_orders l
	where status = 'filled'
	and upper(price_currency) in (select currency from ng_site)
)
, amm_orders_ as (
	select 
	user_id
	,'amm_order_' || a.id transaction_id
	,'amm_order' transaction_type
	,created_at
	,filled_at
	,updated_at
	,source_coin
	,source_amount
	,destination_coin fiat_currency
	,actual_destination_amount fiat_amount
	from public.amm_orders a
	where status = 'filled'
	and upper(destination_coin) in (select currency from ng_site)
)
, trades_ as (
	select
	seller_id user_id
	,'trading_'|| t.id transaction_id
	,'trading' transaction_type
	,created_at
	,paid_at filled_at
	,updated_at
	,coin_currency source_coin
	,coin_amount source_amount
	,fiat_currency
	,fiat_amount
	from public.trades t
	where status = 'paid'
	and upper(country_code) in (select country_code from ng_site)
)
, all_offramp_transaction as (
	select 
		trans_.*
		, date_part('week',trans_.filled_at) transaction_week_number
	from
	(
		select * from limit_orders_
		union all 
		select * from amm_orders_
		union all 
		select * from trades_
	) trans_
)
	select
		a.*
		,u.usd_rate
		,(a.fiat_amount / u.usd_rate) usd_amount
	from all_offramp_transaction a
	inner join public.usd_rate u
	on date(a.filled_at) = date(u.date)
	and upper(a.fiat_currency) = u.currency
);

select * from view_ng_site_offramp_transaction;