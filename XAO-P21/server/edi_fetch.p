/* Support module for edi-report.pl
   Dumps an EDI message by given doc_number
*/

DEF VAR dnum LIKE p21.edidoc_h.doc_number NO-UNDO.

ASSIGN dnum=INTEGER(OS-GETENV("P0")).

FOR EACH p21.edidoc_d WHERE edidoc_d.doc_number = dnum USE-INDEX document NO-LOCK:
    PUT UNFORMATTED edidoc_d.data skip.
END.
