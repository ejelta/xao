/* Lists all customers registered in P21.
 * Output format is as supported by XAO::P21 server
*/

DEF VAR d_d AS CHAR FORMAT "x(10)" NO-UNDO.
 
d_d="\001".
 
FOR EACH p21.customer:
    PUT UNFORMATTED
        p21.customer.bill_to_name	d_d
        p21.customer.cust_code		d_d
        p21.customer.bill_to_addr1	d_d
        p21.customer.bill_to_addr2	d_d
        p21.customer.bill_to_addr3	d_d
        p21.customer.bill_to_city	d_d
        p21.customer.bill_to_state	d_d
        p21.customer.bill_to_zip	d_d
        p21.customer.telephone		d_d
    .
 
    FIND FIRST p21.cust_aux WHERE p21.cust_aux.cust_code = p21.customer.cust_code
                            SHARE-LOCK NO-ERROR.
    IF AVAILABLE p21.cust_aux THEN
        PUT UNFORMATTED
            p21.cust_aux.aux_fax	d_d
            p21.cust_aux.email_address	d_d
        .
    ELSE
        PUT UNFORMATTED
            ?				d_d
            ?				d_d
        .
 
    PUT UNFORMATTED
        p21.customer.slm_number		d_d
        p21.customer.first_sale		d_d
        p21.customer.stax_exemp		d_d
        p21.customer.stax_flag_disp	d_d
        p21.customer.otax_exemp		d_d
        p21.customer.otax_flag_disp	d_d
        p21.customer.inv_batch		d_d
        p21.customer.sic		d_d
        p21.customer.frt_code_disp      d_d
        p21.customer.cred_type_disp     d_d
        p21.customer.default_loc	d_d
    .

    FIND FIRST p21.cust_ctrl WHERE p21.cust_ctrl.cust_code = p21.customer.cust_code
                             SHARE-LOCK NO-ERROR.

    IF AVAILABLE p21.cust_ctrl THEN
        PUT UNFORMATTED
            p21.cust_ctrl.sales_loc	d_d
            p21.cust_ctrl.source_loc    skip
        .
    ELSE
        PUT UNFORMATTED
            ?                           d_d
            ?                           skip
        .
END.
