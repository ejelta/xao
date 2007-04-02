/* Lists all customers registered in P21.
 * Output format is as supported by XAO::P21 server
*/
DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR v_custcode LIKE p21.customer.cust_code.

ASSIGN d_d="\001".

ASSIGN v_custcode=OS-GETENV("P0").

FIND FIRST p21.customer WHERE p21.customer.cust_code = v_custcode
                        SHARE-LOCK NO-ERROR.

IF AVAILABLE p21.customer THEN DO:

    FIND FIRST p21.cust_aux WHERE p21.cust_aux.cust_code = v_custcode
                            SHARE-LOCK NO-ERROR.

    IF AVAILABLE p21.cust_aux THEN DO:
        PUT UNFORMATTED
            p21.customer.bill_to_name		d_d
            p21.customer.cust_code		d_d
            p21.customer.bill_to_addr1		d_d
            p21.customer.bill_to_addr2		d_d
            p21.customer.bill_to_addr3		d_d
            p21.customer.bill_to_city		d_d
            p21.customer.bill_to_state		d_d
            p21.customer.bill_to_zip		d_d
            p21.customer.telephone		d_d
            p21.cust_aux.aux_fax		d_d
            p21.cust_aux.email_address		d_d
            p21.customer.slm_number		d_d
            p21.customer.first_sale		d_d
            p21.customer.stax_exemp		d_d
            p21.customer.stax_flag_disp		d_d
            p21.customer.otax_exemp		d_d
            p21.customer.otax_flag_disp		d_d
            p21.customer.inv_batch		d_d
            p21.customer.sic			d_d
            p21.customer.default_loc		d_d
        .

        FIND FIRST p21.cust_ctrl WHERE p21.cust_ctrl.cust_code = v_custcode
                                 SHARE-LOCK NO-ERROR.

        IF AVAILABLE p21.cust_ctrl THEN
            PUT UNFORMATTED
                p21.cust_ctrl.sales_loc		d_d
                p21.cust_ctrl.source_loc        skip
            .
        ELSE
            PUT UNFORMATTED
                ?                               d_d
                ?                               skip
            .
    END.
END.
