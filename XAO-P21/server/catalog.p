DEFINE NEW SHARED VARIABLE d_d as char format "x(20)" no-undo.
d_d="\t".
def var alt_ut_name like item_unit_data.alt_ut_name no-undo.
def var alt_ut_size like item_unit_data.alt_ut_size no-undo.

define query qcatalog for catalog, item_unit_data.
open query qcatalog for each catalog, each item_unit_data
        left outer-join where catalog.frecno = item_unit_data.item_rec
                        and item_unit_data.item_type = 1.

get first qcatalog.

do while available (catalog):
/*
        assign
                alt_ut_name=''
                alt_ut_size=0.
                */
        assign
                alt_ut_name=item_unit_data.alt_ut_name
                alt_ut_size=item_unit_data.alt_ut_size.
        put unformatted
                catalog.item_code d_d
		catalog.prod_group d_d
                catalog.pkg_size d_d
                catalog.sales_unit d_d
                catalog.sku d_d
                catalog.prices_list_price d_d
                alt_ut_name d_d
                alt_ut_size d_d
                catalog.desc1 d_d catalog.desc2  d_d
                catalog.upc_code d_d
		catalog.cat_page
                "\n".
        get next qcatalog.                
end.        
