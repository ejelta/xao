def var onum like p21.ord_line.ord_number.
def var snum as char.
def var cust as char.
def var open_qty as decimal.
def var net_price as decimal.
def buffer exp_date for p21.req_exp_date.
ASSIGN cust = OS-GETENV("P0")
snum = OS-GETENV("P1")
onum = INTEGER(snum).
find first p21.order where p21.order.ord_number = onum no-lock.                 
        if p21.order.cust_code = cust THEN
          for each p21.ord_line where p21.ord_line.ord_number = onum no-lock:
             ASSIGN open_qty = (p21.ord_line.ord_qty -
                  p21.ord_line.inv_qty -
                  p21.ord_line.canc_qty)
             net_price = (p21.ord_line.ut_price *
                  p21.ord_line.multiplier).
             put unformatted
                p21.ord_line.item_code chr(1)
                p21.ord_line.desc1 chr(1)
                p21.ord_line.ord_qty chr(1)
                p21.ord_line.unit chr(1)
                net_price chr(1)
                open_qty chr(1).
             if (p21.ord_line.ut_size ne 0) then
                put unformatted
                        ((open_qty * net_price) / p21.ord_line.ut_size) chr(1).
             else
                put unformatted "n/a" chr(1).
             find first exp_date where
                        exp_date.ord_number eq p21.ord_line.ord_number
                    and exp_date.line_number eq p21.ord_line.line_number
                        NO-LOCK NO-ERROR.
             if available exp_date then
                put unformatted
                exp_date.exp_date chr(1).
             else
                put unformatted "none" chr(1).
             put unformatted
                p21.ord_line.last_shipment chr(1).
             put unformatted
                p21.ord_line.disposition chr(1)
                p21.ord_line.disposition_desc skip.
          end.
        else
          put unformatted
             "ACCESS DENIED:" chr(1)                                         
             "You cannot" chr(1)                                             
             "view other customer's" chr(1)                                  
             "information" chr(1)                                            
             "" skip.                                                        
