DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR onum AS INTEGER NO-UNDO.

/* Field separator
*/
ASSIGN d_d="\001".

/* Supplied order ID
*/
ASSIGN onum=INTEGER(OS-GETENV("P0")).

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
        ord_line.disposition_desc       skip
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
        wbw_head.cust_code              skip
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
