/* Selects order items after specified date for use in 'bought before'
 * feature of the web site (Your Products tab in the interface)
*/
DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR base_date AS DATE NO-UNDO.

ASSIGN base_date=date(INTEGER(OS-GETENV("P1")),
                      INTEGER(OS-GETENV("P2")),
                      INTEGER(OS-GETENV("P0"))).

ASSIGN d_d="\001".

FOR EACH p21.ord_line WHERE ord_line.entry_date GT base_date NO-LOCK:
    FIND FIRST p21.order WHERE order.ord_number EQ ord_line.ord_number.
    IF AVAILABLE p21.order THEN DO:
        PUT UNFORMATTED
            order.cust_code "\t"
            order.ord_date "\t"
            ord_line.ord_number "\t"
            ord_line.item_code "\t"
            ord_line.entry_date "\t"
        SKIP.
    END.
END.
