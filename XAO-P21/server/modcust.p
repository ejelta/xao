def var cust_code like p21.customer.cust_code.
assign cust_code = OS-GETENV("P0").
find first p21.customer
        where p21.customer.cust_code = cust_code
        no-error.
if available p21.customer then do:
        find first p21.cust_aux where p21.cust_aux.cust_code = cust_code
                no-error.
        if available p21.cust_aux then do:
        assign
        p21.customer.bill_to_name = OS-GETENV("P1")
        p21.customer.bill_to_addr1 = OS-GETENV("P2")
        p21.customer.bill_to_addr2 = OS-GETENV("P3")
        p21.customer.bill_to_addr3 = OS-GETENV("P4")
        p21.customer.bill_to_city = OS-GETENV("P5")
        p21.customer.bill_to_state = OS-GETENV("P6")
        p21.customer.bill_to_zip = OS-GETENV("P7")
        p21.customer.telephone = OS-GETENV("P8")
        p21.cust_aux.aux_fax = OS-GETENV("P9")
        p21.cust_aux.email_address = OS-GETENV("P10")
        p21.customer.slm_number = INTEGER(OS-GETENV("P11"))
        p21.customer.first_sale = DATE(OS-GETENV("P12")).
        end.
end.        
