DEFINE NEW SHARED VARIABLE d_d as char format "x(20)" no-undo.
 
d_d="\001".
 
  FOR EACH p21.customer :
  put unformatted
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
    d_d.
 
    DEFINE VARIABLE v_custcode LIKE p21.cust_aux.cust_code NO-UNDO.
    v_custcode=p21.customer.cust_code.
    FOR FIRST p21.cust_aux WHERE p21.cust_aux.cust_code = v_custcode :
    put unformatted
    p21.cust_aux.aux_fax
    d_d
    p21.cust_aux.email_address
    d_d.
    END.
 
    put unformatted
    p21.customer.slm_number
    d_d
    p21.customer.first_sale.
  put unformatted "\n".
      END.
