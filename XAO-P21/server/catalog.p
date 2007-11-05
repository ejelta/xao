DEF VAR d_d as char format "x(20)" NO-UNDO.
DEF VAR v_free LIKE p21.item_status.free.
DEF VAR v_allocated LIKE p21.item_status.allocated.

d_d="\t".

FOR EACH catalog NO-LOCK:
    ASSIGN
        v_free=0
        v_allocated=0
    .

    /* Counting stock levels manually, not relying on the "0" division for the total
     * to exclude Mexico divisions
    */
    FIND FIRST p21.item WHERE item.item_code EQ catalog.item_code NO-LOCK NO-ERROR.
    IF AVAILABLE(p21.item) THEN
        FOR EACH p21.item_status WHERE item_status.item_rec = item.frecno
                                   AND item_status.loc_id <> 0
                                   AND item_status.loc_id <> 10
                                   AND item_status.loc_id <> 13
                                   AND item_status.loc_id <> 15
                                   AND item_status.loc_id <> 37
                                   AND (item_status.allocated > 0 OR item_status.free > 0)
                                   NO-LOCK:
            ASSIGN
                v_free=p21.item_status.free
                v_allocated=p21.item_status.allocated
            .
        END.
    .

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
        catalog.catg_list               d_d
        v_free                          d_d
        v_allocated
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
