DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR onum AS INTEGER NO-UNDO.
DEF VAR rdate AS DATE INIT ? NO-UNDO.

/* Field separator
*/
ASSIGN d_d="\001".

/* Supplied order ID
*/
ASSIGN onum=INTEGER(OS-GETENV("P0")).

/* Getting default req_date from p21.order
*/
FOR FIRST p21.order WHERE p21.order.ord_number = onum NO-LOCK:
    ASSIGN rdate=p21.order.req_date.
END.

/* First we display general line item information and statuses.
*/
FOR EACH p21.ord_line WHERE ord_line.ord_number = onum NO-LOCK:
    PUT UNFORMATTED
        "LINE"                          d_d
        ord_line.line_number            d_d
        ord_line.item_code              d_d
        ord_line.entry_date             d_d
        ord_line.ord_qty                d_d
        ord_line.inv_qty                d_d
        ord_line.canc_qty               d_d
        ord_line.ut_price               d_d
        ord_line.ut_size                d_d
        ord_line.disposition            d_d
        ord_line.disposition_desc       d_d
        ord_line.ship_loc               d_d
    .

    FIND FIRST p21.req_exp_date WHERE p21.req_exp_date.ord_number = onum AND
                                      p21.req_exp_date.line_number = ord_line.line_number
                                      NO-LOCK NO-ERROR.
    IF AVAILABLE(p21.req_exp_date) THEN
        PUT UNFORMATTED
            p21.req_exp_date.req_date
        .
    ELSE
        PUT UNFORMATTED
            rdate
        .
    PUT UNFORMATTED
        skip
    .
END.

/* And now shipping information and invoices
*/
FOR EACH wbw_head WHERE wbw_head.ord_number = onum NO-LOCK:
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
        wbw_head.ship_branch            skip
    .

END.

/* And finally content of each invoice
*/
FOR EACH wbw_line WHERE wbw_line.ord_number = onum NO-LOCK:
    PUT UNFORMATTED
        "ITEM"                          d_d
        wbw_line.ship_number            d_d
        wbw_line.item_code              d_d
        wbw_line.inv_qty                d_d
        wbw_line.line_number            skip
    .
END.
