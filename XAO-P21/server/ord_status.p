DEF VAR d_d AS CHAR.
DEF VAR open_qty AS DECIMAL.
DEF VAR net_price AS DECIMAL.
DEF VAR snum AS CHAR.
DEF VAR onum AS INTEGER.
DEF VAR total_stax_amt LIKE dyn1.wbw_head.total_stax_amt.
DEF VAR out_freight LIKE dyn1.wbw_head.out_freight.

/* Separator
*/
d_d=chr(1).

/* Order ID
ASSIGN snum=OS-GETENV("P0").
onum=INTEGER(snum).
*/
ASSIGN onum=INTEGER(OS-GETENV("P0")).

/* Tax and freight amount for the order if available
*/

FIND FIRST dyn1.wbw_head WHERE dyn1.wbw_head.ord_number = onum
                         NO-LOCK NO-ERROR.
IF available(dyn1.wbw_head) THEN
    ASSIGN 
        total_stax_amt=dyn1.wbw_head.total_stax_amt
        out_freight=dyn1.wbw_head.out_freight
    .
ELSE
    ASSIGN
        total_stax_amt=0
        out_freight=0
    .

/* Line items and their status and open quantities.
   We duplicate tax on every line.
*/
FOR EACH p21.ord_line WHERE p21.ord_line.ord_number = onum NO-LOCK:
    ASSIGN
        open_qty = (p21.ord_line.ord_qty -
                    p21.ord_line.inv_qty -
                    p21.ord_line.canc_qty)
        net_price = (p21.ord_line.ut_price *
                     p21.ord_line.multiplier)
    .

    PUT UNFORMATTED
        p21.ord_line.item_code			d_d
        p21.ord_line.ord_qty			d_d
        open_qty				d_d
        net_price				d_d
        total_stax_amt				d_d
	out_freight				d_d
        p21.ord_line.unit			d_d
        p21.ord_line.ut_size			d_d
        p21.ord_line.last_shipment		d_d
        p21.ord_line.disposition		d_d
        p21.ord_line.disposition_desc		skip
    .
END.
