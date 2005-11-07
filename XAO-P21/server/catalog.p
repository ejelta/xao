DEF VAR d_d as char format "x(20)" NO-UNDO.

d_d="\t".

FOR EACH catalog NO-LOCK:
    PUT UNFORMATTED
        catalog.item_code               d_d
        catalog.prod_group              d_d
        catalog.sales_group             d_d
        catalog.vend_number             d_d
        catalog.pkg_size                d_d
        catalog.sales_unit              d_d
        catalog.sku                     d_d
        catalog.desc1                   d_d
        catalog.desc2                   d_d
        catalog.upc_code                d_d
        catalog.cat_page                d_d
        catalog.purc_group              d_d
        catalog.prices_list_price       d_d
        catalog.prices_std_cost         d_d
        catalog.prices_col1_price       d_d
        catalog.prices_col2_price       d_d
        catalog.prices_col3_price       d_d
        catalog.catg_list
    .

    FOR EACH item_unit_data WHERE item_unit_data.item_rec = catalog.frecno
                            AND item_unit_data.item_type = 1.
        PUT UNFORMATTED
            d_d
            item_unit_data.alt_ut_name "/" item_unit_data.alt_ut_size
        .
    END.

    PUT UNFORMATTED SKIP.
END.        
