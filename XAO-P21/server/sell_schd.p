DEF VAR fs AS CHAR FORMAT "x(20)" NO-UNDO.

ASSIGN fs="\t".

FOR EACH p21.sell_schd NO-LOCK:
   PUT UNFORMATTED
       sell_schd.disc_group		fs
       sell_schd.disc_basis_disp	fs
       sell_schd.disc_code_disp		fs
       sell_schd.disc_type_disp		fs
       sell_schd.breaks[1]		"/"
       sell_schd.breaks[2]		"/"
       sell_schd.breaks[3]		"/"
       sell_schd.breaks[4]		"/"
       sell_schd.breaks[5]		"/"
       sell_schd.breaks[6]		"/"
       sell_schd.breaks[7]		"/"
       sell_schd.breaks[8]		fs
       sell_schd.discounts[1]		"/"
       sell_schd.discounts[2]		"/"
       sell_schd.discounts[3]		"/"
       sell_schd.discounts[4]		"/"
       sell_schd.discounts[5]		"/"
       sell_schd.discounts[6]		"/"
       sell_schd.discounts[7]		"/"
       sell_schd.discounts[8]
       "\n"
   .
END.
