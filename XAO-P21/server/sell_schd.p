DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.

ASSIGN d_d="\t".

/* We ignore COST override records. For the rest we return the same
   data layout that is returned from sell_schd table
*/
FOR EACH p21.pc_override WHERE pc_override.pc_flag_disp EQ "PRICE" NO-LOCK:
   PUT UNFORMATTED
       "*"                            d_d	/* sell_schd.disc_group */
       "*"                            d_d       /* sell_schd.vend_number */
       pc_override.basis_disp         d_d       /* sell_schd.disc_basis_disp - ITEM, etc */
       pc_override.source_price_disp  d_d       /* sell_schd.disc_code_disp - COL1, etc */
       pc_override.method_disp        d_d	/* sell_schd.disc_type_disp - MULT, PRICE, etc */
       pc_override.breaks[1]          "/"
       pc_override.breaks[2]          "/"
       pc_override.breaks[3]          "/"
       pc_override.breaks[4]          "/"
       pc_override.breaks[5]          "/"
       pc_override.breaks[6]          "/"
       pc_override.breaks[7]          "/"
       pc_override.breaks[8]          d_d
       pc_override.disc[1]            "/"
       pc_override.disc[2]            "/"
       pc_override.disc[3]            "/"
       pc_override.disc[4]            "/"
       pc_override.disc[5]            "/"
       pc_override.disc[6]            "/"
       pc_override.disc[7]            "/"
       pc_override.disc[8]            d_d
       pc_override.item_code          skip
   .
END.

/* Price schedules in the same format
*/
FOR EACH p21.sell_schd NO-LOCK:
   PUT UNFORMATTED
       sell_schd.disc_group             d_d
       sell_schd.vend_number            d_d
       sell_schd.disc_basis_disp        d_d
       sell_schd.disc_code_disp         d_d
       sell_schd.disc_type_disp         d_d
       sell_schd.breaks[1]              "/"
       sell_schd.breaks[2]              "/"
       sell_schd.breaks[3]              "/"
       sell_schd.breaks[4]              "/"
       sell_schd.breaks[5]              "/"
       sell_schd.breaks[6]              "/"
       sell_schd.breaks[7]              "/"
       sell_schd.breaks[8]              d_d
       sell_schd.discounts[1]           "/"
       sell_schd.discounts[2]           "/"
       sell_schd.discounts[3]           "/"
       sell_schd.discounts[4]           "/"
       sell_schd.discounts[5]           "/"
       sell_schd.discounts[6]           "/"
       sell_schd.discounts[7]           "/"
       sell_schd.discounts[8]           d_d
       ""                               skip    /* pc_override.item_code */
   .
END.
