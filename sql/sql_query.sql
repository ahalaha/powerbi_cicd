create or replace view view_ng_users_transaction as (
with ng_users as (
	select 
		u.id user_id
	from public.users u
	where country_code = 'au'
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
)
	select
		trans_.*
		,date_part('week',trans_.filled_at) transaction_week_number
	from ng_users
	inner join 
	(
		select * from limit_orders_
		union all 
		select * from amm_orders_
		union all 
		select * from trades_
	) trans_
	on ng_users.user_id = trans_.user_id
)

-- select 
-- 	*
-- from view_ng_users_transaction