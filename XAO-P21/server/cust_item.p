DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.

ASSIGN d_d="\t".

FOR EACH cust_item.
    IF cust_item.fixed_price THEN
        PUT UNFORMATTED
            cust_item.cust_code		d_d
            cust_item.item_code		d_d
            cust_item.part_number   d_d
            cust_item.sales_price	skip
        .
END.
