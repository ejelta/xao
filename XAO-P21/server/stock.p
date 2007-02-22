/* Michael, 2/14/2007

SELECT item_0.ITEM_CODE, item_0.DESC1, item_0.DESC2, item_0.PROD_GROUP, item_status_0.FREE, item_status_0.ALLOCATED, item_status_0.LOC_ID

FROM P21.item item_0, P21.item_status item_status_0

WHERE item_0.FRECNO = item_status_0.ITEM_REC AND
      ( (item_status_0.LOC_ID=3)
        AND
        (item_status_0.FREE>0.0)
        AND
        (item_status_0.ALLOCATED=0.0)
        OR
        (item_status_0.LOC_ID=3)
        AND
        (item_status_0.FREE=0)
        AND
        (item_status_0.ALLOCATED>0.0)
        OR
        (item_status_0.LOC_ID=3)
        AND
        (item_status_0.FREE>0.0)
        AND
        (item_status_0.ALLOCATED>0.0)
      )
*/
 
DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR v_itemcode LIKE p21.item.item_code.

ASSIGN v_itemcode=OS-GETENV("P0").
ASSIGN d_d="\t".

FOR EACH p21.item WHERE item.item_code EQ v_itemcode NO-LOCK:
    FOR EACH p21.item_status WHERE item_status.item_rec = item.frecno AND (item_status.allocated > 0 OR item_status.free > 0) NO-LOCK:
        PUT UNFORMATTED
            p21.item.item_code        d_d
            p21.item_status.loc_id    d_d
            p21.item_status.free      d_d
            p21.item_status.allocated d_d
            skip
        .
    END.
END.
