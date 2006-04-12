DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR onum AS INTEGER NO-UNDO.
DEF VAR i AS INTEGER NO-UNDO.
DEF VAR rdate AS DATE INIT ? NO-UNDO.
DEF VAR sflag LIKE p21.order.suspend_flag NO-UNDO.
DEF VAR c_price LIKE p21.ord_line.ut_price NO-UNDO.

/* Field separator
*/
ASSIGN d_d="\001".

/* Supplied order ID
*/
ASSIGN onum=INTEGER(OS-GETENV("P0")).

/* Starting transaction here to get consistent results about
 * the order. Lock up if we have to wait.
*/
DO TRANSACTION:

    /* Records in p21.order allow us to look into the fresh orders, not invoiced yet
    */
    FOR FIRST p21.order WHERE p21.order.ord_number = onum SHARE-LOCK:
        ASSIGN rdate=p21.order.req_date.
        ASSIGN sflag=p21.order.suspend_flag.

        PUT UNFORMATTED
            "ORDER"                         d_d
            order.line_number               d_d
            order.cust_code                 d_d
            order.cust_po                   d_d
            order.sales_loc                 d_d
            order.req_date                  d_d
            order.ord_date                  d_d
            order.suspend_flag              d_d
            skip
        .
    END.

    /* First we display general line item information and statuses.
    */
    FOR EACH p21.ord_line WHERE ord_line.ord_number = onum SHARE-LOCK:
	ASSIGN c_price=ord_line.ut_price * ord_line.multiplier.
        PUT UNFORMATTED
            "LINE"                          d_d
            ord_line.line_number            d_d
            ord_line.item_code              d_d
            ord_line.entry_date             d_d
            ord_line.ord_qty                d_d
            ord_line.inv_qty                d_d
            ord_line.canc_qty               d_d
            c_price                         d_d
            ord_line.ut_size                d_d
            ord_line.disposition            d_d
            ord_line.disposition_desc       d_d
            ord_line.ship_loc               d_d
        .

        FIND FIRST p21.req_exp_date WHERE p21.req_exp_date.ord_number = onum AND
                                          p21.req_exp_date.line_number = ord_line.line_number
                                          SHARE-LOCK NO-ERROR.
        IF AVAILABLE(p21.req_exp_date) THEN
            PUT UNFORMATTED
                p21.req_exp_date.req_date   d_d
            .
        ELSE
            PUT UNFORMATTED
                rdate                       d_d
            .
        PUT UNFORMATTED
            sflag
            skip
        .
    END.

    /* And now shipping information and invoices
    */
    FOR EACH wbw_head WHERE wbw_head.ord_number = onum SHARE-LOCK:
        PUT UNFORMATTED
            "INVOICE"                       d_d
            wbw_head.ship_number            d_d
            wbw_head.ord_date               d_d
            wbw_head.inv_date               d_d
            wbw_head.ship_date              d_d
            wbw_head.total_stax_amt         d_d
            wbw_head.out_freight            d_d
            wbw_head.cust_code              d_d
            wbw_head.ship_inst1             d_d
            wbw_head.ship_branch            d_d
            wbw_head.ship_to_name           d_d
            wbw_head.ship_to_addr1          d_d
            wbw_head.ship_to_addr2          d_d
            wbw_head.ship_to_addr3          d_d
            wbw_head.ship_to_city           d_d
            wbw_head.ship_to_state          d_d
            wbw_head.ship_to_zip            d_d
            wbw_head.ar_amt                 d_d
            wbw_head.cust_po                d_d
            wbw_head.sales_loc              skip
        .
    END.

    /* And finally content of each invoice
    */
    FOR EACH wbw_line WHERE wbw_line.ord_number = onum SHARE-LOCK:
        PUT UNFORMATTED
            "ITEM"                          d_d
            wbw_line.ship_number            d_d
            wbw_line.item_code              d_d
            wbw_line.inv_qty                d_d
            wbw_line.line_number            d_d
            wbw_line.part_number            skip
        .
    END.

    FOR EACH p21.blanket WHERE blanket.ord_number EQ onum NO-LOCK:
        i=1.
        DO WHILE i LE 18:
            PUT UNFORMATTED
                "BLANKET"			d_d
                blanket.line_number	        d_d
                blanket.item_code	        d_d
                i				d_d
                blanket.release_exp_date[i]	d_d
                blanket.release_inv_date[i]	d_d
                blanket.release_rel_qty[i]	d_d
                blanket.release_inv_qty[i]	d_d
                blanket.release_allo_qty[i]	d_d
                blanket.release_canc_qty[i]	d_d
                blanket.release_comp_flag[i]	d_d
                blanket.release_disp[i]		skip
            .
            i=(i + 1).
        END.
    END.

/* End transaction
*/
END.
