DEFINE QUERY qitem FOR item, item_unit_data.
OPEN QUERY qitem FOR EACH item, EACH item_unit_data
        LEFT OUTER-JOIN WHERE item.frecno = item_unit_data.item_rec
                AND item_unit_data.item_type = 0.

GET FIRST qitem.

DO WHILE AVAILABLE (item):
        PUT UNFORMATTED
                item.item_code "\t"
		item.prod_group "\t"
                item.pkg_size "\t"
                item.sales_unit "\t"
                item.sku "\t"
                item.prices_list_price "\t"
                item_unit_data.alt_ut_name "\t"
                item_unit_data.alt_ut_size "\t"
                item.desc1 "\t" item.desc2 "\t"
                item.upc_code "\t"
		item.cat_page
                "\n".
        GET NEXT qitem.                
END.        
