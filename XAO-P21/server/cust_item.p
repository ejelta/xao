DEFINE VARIABLE d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEFINE VARIABLE price LIKE cust_item.sales_price NO-UNDO.

ASSIGN d_d="\t".

FOR EACH cust_item NO-LOCK.
    IF cust_item.fixed_price THEN
        ASSIGN price=cust_item.sales_price.
    ELSE
        ASSIGN price=0.

    PUT UNFORMATTED
        cust_item.cust_code             d_d
        cust_item.item_code             d_d
        cust_item.part_number           d_d
        price                           d_d
        cust_item.extended_part         skip
    .
END.
