def var v_custcode like p21.customer.cust_code.
assign v_custcode=OS-GETENV("P0").
find first p21.customer
        where p21.customer.cust_code = v_custcode
        no-lock no-error.
if available p21.customer then do:
    find first p21.cust_aux where p21.cust_aux.cust_code = v_custcode
        no-lock no-error.
    if available p21.cust_aux then do:
  put unformatted
    p21.customer.bill_to_name "\001"
    p21.customer.cust_code
    "\001"
    p21.customer.bill_to_addr1
    "\001"
    p21.customer.bill_to_addr2
    "\001"
    p21.customer.bill_to_addr3
    "\001"
    p21.customer.bill_to_city
    "\001"
    p21.customer.bill_to_state
    "\001"
    p21.customer.bill_to_zip
    "\001"
    p21.customer.telephone
    "\001"
    p21.cust_aux.aux_fax
    "\001"
    p21.cust_aux.email_address
    "\001"
    p21.customer.slm_number
    "\001"
    p21.customer.first_sale.
  put unformatted "\n".
  END.
  end.
