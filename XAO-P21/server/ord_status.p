DEF VAR onum AS INTEGER.

ASSIGN onum=INTEGER(OS-GETENV("P0")).

/* First we display general line item information and statuses.
*/
FOR EACH p21.ord_line WHERE ord_line.ord_number = onum NO-LOCK:
    PUT UNFORMATTED
        "LINE\t"
        ord_line.item_code		"\t"
        ord_line.entry_date		"\t"
        ord_line.ord_qty		"\t"
        ord_line.inv_qty		"\t"
        ord_line.canc_qty		"\t"
        ord_line.disposition		"\t"
        ord_line.disposition_desc	"\n"
    .
END.

/* And now shipping information and invoices
*/
FOR EACH wbw_head WHERE wbw_head.ord_number = onum NO-LOCK:
    PUT UNFORMATTED
	"INVOICE\t"
        wbw_head.ship_number	"\t"
        wbw_head.ord_date	"\t"
        wbw_head.inv_date	"\t"
	wbw_head.ship_date	"\t"
        wbw_head.total_stax_amt	"\t"
        wbw_head.out_freight	"\t"
        wbw_head.cust_code	"\n"
    .

END.

/* And finally content of each invoice
*/
FOR EACH wbw_line WHERE wbw_line.ord_number = onum NO-LOCK:
    PUT UNFORMATTED
        "ITEM\t"
        wbw_line.ship_number	"\t"
        wbw_line.item_code	"\t"
        wbw_line.inv_qty	"\n"
    .
END.
