/* Selects order items after specified date for use in 'bought before'
 * feature of the web site (Your Products tab in the interface)
*/
DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR base_date AS DATE NO-UNDO.

ASSIGN base_date=date(INTEGER(OS-GETENV("P1")),
                      INTEGER(OS-GETENV("P2")),
                      INTEGER(OS-GETENV("P0"))).

ASSIGN d_d="\001".

FOR EACH wbw_line WHERE wbw_line.inv_date GT base_date NO-LOCK:
    IF wbw_line.inv_date NE ? THEN
        PUT UNFORMATTED
            wbw_line.cust_code      d_d
            wbw_line.inv_date       d_d
            wbw_line.ord_number     d_d
            wbw_line.item_code      d_d
            wbw_line.inv_date       d_d
        SKIP.
END.
