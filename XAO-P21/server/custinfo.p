/* Lists all customers registered in P21.
 * Output format is as supported by XAO::P21 server
*/

DEF VAR d_d AS CHAR FORMAT "x(20)" NO-UNDO.
DEF VAR v_custcode LIKE p21.cust_aux.cust_code NO-UNDO.
 
d_d="\001".
 
FOR EACH p21.customer:
    PUT UNFORMATTED
        p21.customer.bill_to_name
        d_d
        p21.customer.cust_code
        d_d
        p21.customer.bill_to_addr1
        d_d
        p21.customer.bill_to_addr2
        d_d
        p21.customer.bill_to_addr3
        d_d
        p21.customer.bill_to_city
        d_d
        p21.customer.bill_to_state
        d_d
        p21.customer.bill_to_zip
        d_d
        p21.customer.telephone
        d_d
    .
 
    v_custcode=p21.customer.cust_code.

    FOR FIRST p21.cust_aux WHERE p21.cust_aux.cust_code = v_custcode :
        PUT UNFORMATTED
            p21.cust_aux.aux_fax
            d_d
            p21.cust_aux.email_address
            d_d.
    END.
 
    PUT UNFORMATTED
        p21.customer.slm_number
        d_d
        p21.customer.first_sale
        d_d
        p21.customer.stax_exemp
        "\n"
    .
END.
