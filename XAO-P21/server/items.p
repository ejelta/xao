define query qitem for item, item_unit_data.
open query qitem for each item, each item_unit_data
        left outer-join where item.frecno = item_unit_data.item_rec
                and item_unit_data.item_type = 0.

get first qitem.

do while available (item):
        put unformatted
                item.item_code "\t"
		item.prod_group "\t"
                item.pkg_size "\t"
                item.sales_unit "\t"
                item.sku "\t"
                item.prices_list_price "\t"
                item_unit_data.alt_ut_name "\t"
                item_unit_data.alt_ut_size "\t"
                item.desc1 "\t" item.desc2 "\t"
                item.upc_code 
                "\n".
        get next qitem.                
end.        
