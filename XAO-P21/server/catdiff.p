DEF VAR d_d as char format "x(20)" NO-UNDO.
DEF VAR cat_units as char format "x(100)" NO-UNDO.
DEF VAR itm_units as char format "x(100)" NO-UNDO.
DEF VAR errmsg as char format "x(20)" NO-UNDO.

d_d="\t".

PUT UNFORMATTED
    "catalog.item_code"            d_d
    "Message"                      d_d
    "catalog.prices_list_price"    d_d
    "catalog.prices_std_cost"      d_d
    "catalog.prices_col1_price"    d_d
    "catalog.prices_col2_price"    d_d
    "catalog.prices_col3_price"    d_d
    "catalog.sales_group"          d_d
    "catalog.vend_number"          d_d
    "item.prices_list_price"       d_d
    "item.prices_std_cost"         d_d
    "item.prices_col1_price"       d_d
    "item.prices_col2_price"       d_d
    "item.prices_col3_price"       d_d
    "item.sales_group"             d_d
    "item.vend_number"             d_d
    "catalog.pkg_size"             d_d
    "catalog.sales_unit"           d_d
    "catalog.sku"                  d_d
    "item.pkg_size"                d_d
    "item.sales_unit"              d_d
    "item.sku"                     d_d
    "catalog.desc1"                d_d
    "catalog.desc2"                d_d
    "catalog.upc_code"             d_d
    "catalog.prod_group"           d_d
    "catalog.purc_group"           d_d
    "catalog.cat_page"             d_d
    "catalog.catg_list"            d_d
    "item.desc1"                   d_d
    "item.desc2"                   d_d
    "item.upc_code"                d_d
    "item.prod_group"              d_d
    "item.purc_group"              d_d
    "item.cat_page"                d_d
    "item.catg_list"               d_d
    SKIP
.

FOR FIRST item NO-LOCK:
    FIND FIRST catalog WHERE catalog.item_code EQ item.item_code NO-LOCK NO-ERROR.
    IF NOT AVAILABLE(catalog) THEN DO:
        PUT UNFORMATTED item.item_code d_d "NOT-IN-CATALOG" SKIP.
        NEXT.
    END.

    cat_units="".
    itm_units="".
    FOR EACH item_unit_data WHERE item_unit_data.item_rec = catalog.frecno
                            AND item_unit_data.item_type = 1.
        IF cat_units NE "" THEN cat_units=cat_units ";".
        cat_units=cat_units item_unit_data.alt_ut_name "/" item_unit_data.alt_ut_size.
    END.

PUT UNFORMATTED "c.frecno=" catalog.frecno "i.frecno=" item.frecno "cu=" cat_units SKIP.

    errmsg="".

    IF (
        catalog.prices_list_price       NE item.prices_list_price OR
        catalog.prices_std_cost         NE item.prices_std_cost OR
        catalog.prices_col1_price       NE item.prices_col1_price OR
        catalog.prices_col2_price       NE item.prices_col2_price OR
        catalog.prices_col3_price       NE item.prices_col3_price OR
        catalog.sales_group             NE item.sales_group OR
        catalog.vend_number             NE item.vend_number
    ) THEN errmsg="PRICES-DIFFER".
    ELSE IF (
        catalog.sku                     NE item.sku OR
        catalog.pkg_size                NE item.pkg_size OR
        catalog.sales_unit              NE item.sales_unit
    ) THEN errmsg="UNITS-DIFFER".
    ELSE IF (
        catalog.desc1                   NE item.desc1 OR
        catalog.desc2                   NE item.desc2 OR
        catalog.upc_code                NE item.upc_code OR
        catalog.prod_group 		NE item.prod_group OR
        catalog.purc_group              NE item.purc_group
    ) THEN errmsg="DESCR-DIFFER".

    IF errmsg NE "" THEN DO:
        PUT UNFORMATTED
            catalog.item_code            d_d
            errmsg                       d_d
            catalog.prices_list_price    d_d
            catalog.prices_std_cost      d_d
            catalog.prices_col1_price    d_d
            catalog.prices_col2_price    d_d
            catalog.prices_col3_price    d_d
            catalog.sales_group          d_d
            catalog.vend_number          d_d
            item.prices_list_price       d_d
            item.prices_std_cost         d_d
            item.prices_col1_price       d_d
            item.prices_col2_price       d_d
            item.prices_col3_price       d_d
            item.sales_group             d_d
            item.vend_number             d_d
            catalog.pkg_size             d_d
            catalog.sales_unit           d_d
            catalog.sku                  d_d
            item.pkg_size                d_d
            item.sales_unit              d_d
            item.sku                     d_d
            catalog.desc1                d_d
            catalog.desc2                d_d
            catalog.upc_code             d_d
            catalog.prod_group           d_d
            catalog.purc_group           d_d
            catalog.cat_page             d_d
            catalog.catg_list            d_d
            item.desc1                   d_d
            item.desc2                   d_d
            item.upc_code                d_d
            item.prod_group              d_d
            item.purc_group              d_d
            item.cat_page                d_d
            item.catg_list               d_d
            SKIP
        .
    END.
END.
