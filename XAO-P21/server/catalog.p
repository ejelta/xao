DEF VAR d_d as char format "x(20)" NO-UNDO.

DEF VAR mult LIKE p21.sell_schd.discounts[1] NO-UNDO.
DEF VAR price AS DECIMAL NO-UNDO.

DEF VAR alt_ut_name LIKE item_unit_data.alt_ut_name NO-UNDO.
DEF VAR alt_ut_size LIKE item_unit_data.alt_ut_size NO-UNDO.

d_d="\t".

DEFINE QUERY qcatalog FOR catalog, item_unit_data.
OPEN QUERY qcatalog FOR EACH catalog, EACH item_unit_data
        LEFT OUTER-JOIN WHERE catalog.frecno = item_unit_data.item_rec
                        AND item_unit_data.item_type = 1.

GET FIRST qcatalog.

DO WHILE AVAILABLE (catalog):
    ASSIGN
        alt_ut_name=item_unit_data.alt_ut_name
        alt_ut_size=item_unit_data.alt_ut_size
    .

    FIND FIRST sell_schd WHERE sell_schd.disc_group = catalog.sales_group
                         NO-LOCK NO-ERROR.
    IF AVAILABLE(sell_schd) THEN
	ASSIGN mult=sell_schd.discounts[1].
    ELSE
	ASSIGN mult=1.

    ASSIGN price=catalog.prices_col1_price * mult.

    PUT UNFORMATTED
        catalog.item_code	d_d
        catalog.prod_group	d_d
        catalog.pkg_size	d_d
        catalog.sales_unit	d_d
        catalog.sku		d_d
        price			d_d
        alt_ut_name		d_d
        alt_ut_size		d_d
        catalog.desc1		d_d
        catalog.desc2		d_d
        catalog.upc_code	d_d
        catalog.cat_page	skip
    .

    GET NEXT qcatalog.                
END.        
