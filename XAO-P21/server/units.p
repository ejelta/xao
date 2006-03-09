FOR EACH unit_name NO-LOCK:
   PUT UNFORMATTED
       unit_name.key             "\t"
       unit_name.description     skip
   .
END.
