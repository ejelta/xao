/* Sample code for Acclaim Pricing */
/* This prompts for customer, item, qty, and returns price */

/* /usr/lpp/p21pro/bin/p21pro -c -d /usr/lpp/p21pro/src:/usr/lpp/p21pro/src/include -P "cus_price.p" */

{paths.i}				/* Include Acclaim paths */
{{&INCLUDEP}globvars.i " " "NEW"}	/* Include Acclaim global variables */

DEFINE VARIABLE v_item_code  AS CHARACTER                    NO-UNDO.
DEFINE VARIABLE v_cust_code  AS CHARACTER                    NO-UNDO.
def var v_cust_price_code LIKE p21.customer.price_code NO-UNDO.
def var v_cust_schd_num LIKE p21.customer.schd_number NO-UNDO.
def var v_cust_alt_schd_num LIKE p21.customer.pcode_mult NO-UNDO.
def var v_cust_pcode_mult LIKE p21.customer.pcode_mult NO-UNDO.
def var v_item_ut_size like p21.item.sales_size no-undo.
def var v_item_cost like p21.item.prices_std_cost no-undo.
def var v_sku like p21.item.sku no-undo.
def var v_unit like p21.item.sales_unit no-undo.
def var v_item_desc1 like p21.item.desc1 no-undo.
def var v_item_desc2 like p21.item.desc2 no-undo.
def var v_item_alt_unit_size like p21.item_unit_data.alt_ut_size no-undo.

DEFINE VARIABLE v_item_qty   AS DECIMAL FORMAT ">>>>9.9999"  NO-UNDO.
DEFINE VARIABLE v_locsales   AS DECIMAL FORMAT ">>>9"        NO-UNDO.
DEFINE VARIABLE v_locstock   AS DECIMAL FORMAT ">>>9"        NO-UNDO.
DEFINE VARIABLE v_cur_size   AS DECIMAL FORMAT ">>>9"        NO-UNDO.
DEFINE VARIABLE v_cost       AS DECIMAL                      NO-UNDO.

DEFINE VARIABLE of_price           AS DECIMAL      NO-UNDO.	/* Calculated price */
DEFINE VARIABLE of_mult            AS DECIMAL      NO-UNDO.	/* Price multiplier */
DEFINE VARIABLE of_mult_flag       AS INTEGER      NO-UNDO.	/* PRICE , MULT, or DIFF */
DEFINE VARIABLE of_unit_size_mult  AS DECIMAL      NO-UNDO.	/* Price multiplier */
DEFINE VARIABLE of_schd_rec        AS RECID        NO-UNDO.	/* Schedule record # */
DEFINE VARIABLE of_over_rec        AS RECID        NO-UNDO.	/* Override record # */
DEFINE VARIABLE of_cuit_rec        AS RECID        NO-UNDO.	/* Cust-item record #*/
DEFINE VARIABLE of_special         AS INTEGER      NO-UNDO.	/* 1=last price */
DEFINE VARIABLE of_mult_recids     AS CHARACTER    NO-UNDO.	/* Mult o-ride recids*/
DEFINE VARIABLE of_special_date    AS DATE INIT ?  NO-UNDO.	/* Special date field   */

DEFINE VARIABLE of_price_gen_src   LIKE p21.spad_line.GEN_PRICE   NO-UNDO.  /* General price source */
DEFINE VARIABLE of_price_spec_src  LIKE p21.spad_line.SPEC_PRICE  NO-UNDO.

/* Specific price source */
DEFINE VARIABLE of_cost_list      AS DECIMAL  NO-UNDO.  /* Custom  */
DEFINE VARIABLE of_cost           AS DECIMAL  NO-UNDO.  /* Calculated cost */
DEFINE VARIABLE of_cost_gen_src   LIKE p21.spad_line.GEN_PRICE   NO-UNDO. /* General cost source */
DEFINE VARIABLE of_cost_spec_src  LIKE p21.spad_line.SPEC_PRICE  NO-UNDO. /* Specific cost source */

PROCEDURE ip_pricing: /* Contains call to pricing routine */
    RUN p21/common/pricing.p (
      INPUT v_locsales, /* Sales location */
      INPUT v_locstock, /* Stocking location */
      INPUT v_cust_code, /* Customer to price for */
      INPUT v_cust_code, /* Common customer code if item part number a 'common cust id', else reg customer */
      INPUT v_cust_price_code,
      input v_cust_schd_num,
      input v_cust_alt_schd_num,
      input v_cust_pcode_mult,
      INPUT v_item_code, /* Item code, or part number if cust_item */
      INPUT v_item_qty, /* Quantity to price, in eaches (mult by req unit size) */
      INPUT v_cur_size, /* Required unit size (result price will be in this unit size; 1 for SKU) */
      INPUT v_cost, /* Cost in above "required unit size" terms  (sometimes used as price source)*/

      OUTPUT of_price, /* Returned price in default unit terms (usually sales unit)*/
      OUTPUT of_mult, /* Multiplier */
      OUTPUT of_mult_flag, /* not used */
      OUTPUT of_unit_size_mult, /* Multiplier to use on of_price to express in required unit size */
      OUTPUT of_schd_rec, /* ? or rec# if sales pricing schedule */
      OUTPUT of_over_rec, /* ? or rec# if overrride */
      OUTPUT of_cuit_rec, /* ? or rec# if cust - item */
      OUTPUT of_special, /* 1 if "last price" returned */
      OUTPUT of_mult_recids, /* Custom */
      OUTPUT of_special_date, /* Last price date if indicator set */
      OUTPUT of_price_gen_src, /* General price source */
      OUTPUT of_price_spec_src, /* Specific price source */
      OUTPUT of_cost_list /* Custom */
    ).

END PROCEDURE.


 ASSIGN v_cust_code = OS-GETENV("P0").
 ASSIGN v_item_code = OS-GETENV("P1").
 ASSIGN v_locsales = decimal(OS-GETENV("P2")).
 ASSIGN v_locstock = decimal(OS-GETENV("P3")).
 ASSIGN v_item_qty = decimal(OS-GETENV("P4")).

/*
 FIND FIRST p21.item NO-LOCK NO-ERROR.
 ASSIGN v_locsales=p21.item.loc_id
	v_locstock = p21.item.loc_id.
*/
 FIND FIRST p21.customer
         WHERE p21.customer.cust_code EQ v_cust_code
         SHARE-LOCK NO-ERROR.
 IF AVAILABLE p21.customer THEN DO:        
         ASSIGN v_cust_price_code=p21.customer.price_code
                v_cust_schd_num=p21.customer.schd_num
                v_cust_pcode_mult=p21.customer.pcode_mult.
 END.               

 FIND FIRST p21.item
         WHERE p21.item.item_code EQ v_item_code
         SHARE-LOCK NO-ERROR.
 IF AVAILABLE p21.item THEN DO:        
         ASSIGN v_item_ut_size = p21.item.pkg_size
                v_item_cost = p21.item.prices_std_cost /* XXX ? */
                v_item_desc1 = p21.item.desc1
                v_item_desc2 = p21.item.desc2
                v_unit = p21.item.sales_unit
                v_item_alt_unit_size = 1.
        FIND FIRST p21.item_unit_data
                WHERE p21.item_unit_data.item_rec EQ p21.item.frecno
                SHARE-LOCK NO-ERROR.
        IF AVAILABLE p21.item_unit_data THEN DO:
                ASSIGN v_item_alt_unit_size = p21.item_unit_data.alt_ut_size.
        END.
 END.               
 else do:
        FIND FIRST p21.catalog
                 WHERE p21.catalog.item_code EQ v_item_code
                 SHARE-LOCK NO-ERROR.
        IF AVAILABLE p21.catalog THEN DO:        
                ASSIGN v_item_ut_size = p21.catalog.pkg_size
                        v_item_cost = p21.catalog.prices_std_cost /* XXX ? */
                        v_item_desc1 = p21.catalog.desc1
                        v_item_desc2 = p21.catalog.desc2
                        v_unit = p21.catalog.sales_unit
                        v_item_alt_unit_size = 1.
                FIND FIRST p21.item_unit_data
                        WHERE p21.item_unit_data.item_rec EQ p21.catalog.frecno
                        SHARE-LOCK NO-ERROR.
                IF AVAILABLE p21.item_unit_data THEN DO:
                        ASSIGN v_item_alt_unit_size = p21.item_unit_data.alt_ut_size.
                END.
        END. 
END.        

v_cur_size = v_item_alt_unit_size.
v_item_qty = v_item_qty * v_cur_size.
v_cost = v_item_cost. /* Price in eaches */

def var vss_cust_item as logical init false no-undo.
FIND p21.S36 WHERE RECID(p21.S36) EQ 36 SHARE-LOCK.
vss_cust_item = p21.S36.cust_item.
if vss_cust_item then do:
        find first p21.cust_item where
                p21.cust_item.cust_code EQ v_cust_code AND
                p21.cust_item.item_code LE v_item_code AND
                p21.cust_item.item_code GE v_item_code
                use-index item_code no-lock no-error.
        if available(p21.cust_item) and p21.cust_item.part_number NE "" then do:
                v_item_code=p21.cust_item.part_number.
        end.
end.

RUN ip_pricing. /* Get price */

put unformatted of_price "\t" of_mult "\n".

quit.
