FOR FIRST p21.catalog NO-LOCK:
    PUT UNFORMATTED "catalog/".
END.        
FOR FIRST p21.customer NO-LOCK:
    PUT UNFORMATTED "customer/".
END.        
FOR FIRST p21.order NO-LOCK:
    PUT UNFORMATTED "order/".
END.        
FOR FIRST wbw_head NO-LOCK:
    PUT UNFORMATTED "wbw_head/".
END.        
PUT UNFORMATTED skip.
