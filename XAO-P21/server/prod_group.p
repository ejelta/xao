DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.

ASSIGN d_d="\t".

FOR EACH p21.prod_group NO-LOCK:
    PUT UNFORMATTED
        prod_group.prod_group   d_d
        prod_group.name         skip
    .
END.
