def var v_fatal as logical init false no-undo.
run lib/alias.p("dyn", "comp", output v_fatal).  
run lib/alias.p("dyn", "fin", output v_fatal).
run lib/alias.p("dyn", "inv", output v_fatal).
run lib/alias.p("dyn", "dat", output v_fatal).
run lib/alias.p("stat", "enum", output v_fatal).  
run lib/alias.p("stat", "menu", output v_fatal).  
run lib/alias.p("stat", "chlp", output v_fatal).
run lib/alias.p("gl", "gl", output v_fatal).     
if (ldbname(1) <> ?) and (ldbname("DICTDB") = ?) then
        create alias DICTDB for database value(ldbname(1)).
if (ldbname(2) <> ?) and (ldbname("DICTDB2") = ?) then
        create alias DICTDB2 for database value(ldbname(2)).
DEFINE NEW  SHARED VARIABLE g_start_date AS DATE INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_end_date AS DATE INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_branch_ikey AS INTEGER INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_default_date AS DATE INIT TODAY NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_default_budget_ikey AS DECIMAL INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_stock_loc AS INTEGER INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_sales_loc AS INTEGER INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_company_ikey AS INTEGER INIT 1 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_group_ikey AS INTEGER INIT 1 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_region_ikey AS INTEGER INIT 1 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_branch_name AS CHARACTER format "x(30)" NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_branch_number AS INTEGER FORMAT ">>>9" INIT 1 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_region_name as char format "x(30)" NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_region_number AS INTEGER FORMAT ">>>9" INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_region_sequence AS INTEGER FORMAT ">>>9" INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_aix_userid as char format "x(20)" no-undo.
DEFINE NEW  SHARED VARIABLE g_userid as char format "x(20)" no-undo.
DEFINE NEW  SHARED VARIABLE g_company_name as char format "X(30)" no-undo.
DEFINE NEW  SHARED VARIABLE g_company_number AS INTEGER NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_module AS INTEGER NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_group_processing AS LOGICAL no-undo.
DEFINE NEW  SHARED VARIABLE g_mgt_summary AS LOGICAL no-undo.
DEFINE NEW  SHARED VARIABLE g_master_acct AS LOGICAL no-undo.
DEFINE NEW  SHARED VARIABLE g_nscost_update AS LOGICAL no-undo.
DEFINE NEW  SHARED VARIABLE g_prepaid_freight AS LOGICAL NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_pro_ap AS LOGICAL FORMAT "Yes/No" INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_pro_ar AS LOGICAL FORMAT "Yes/No" INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_report_group AS CHARACTER FORMAT "X(40)" INIT "" NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_1099_misc_limit AS DECIMAL INIT 600 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_1099_int_limit AS DECIMAL INIT 10 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cust_item AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_tax_exempt AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_serv_dflt AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_prod_group_summ AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ship_pg_summ AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_inv_movement AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ds_pd_cost AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_sales_pg_ns AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ship_pg_ns AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_decimal_track AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_fc_auto_adjoff AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_fifo_cost AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_track_projects AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_home_path as char format "x(64)" no-undo.
DEF NEW  SHARED VAR g_first_ship_fr AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_view_all_ar_grps AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_long_cred_limit AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_lockbox AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_stmt_batch_params AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_stmt_sort AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_aging_br AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_biomed AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_gross_ytd AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_month_close AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_format_tokens AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_gl_branch_live AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_ds_np AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_no_mac_change AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_entry_disc AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_enhanced_edi AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_no_grp_chk AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_dup_ar_chk AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ar_cr_format AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_unpaid_inv_rpt AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_subacct_stmt AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_summary_stmt AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ds_note AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_french AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_foreign_currency AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_stock_items_costing AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_date_batch AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_2priors AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_credit_card AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cost_cntr AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cost_sold AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_autobatch_location AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_advance_bill AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_rent_exch AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cost_prod AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_trans_prod AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_matr_prod AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_rent_prod AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_inv_prod AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_inv_sales AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_iship_sales AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_iship AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_inter_comp AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_inter_ar AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_check_align AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_set_release_date AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ven_branch_total AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_alt_menu AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_customer_accts AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_custom_ar_form AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_5aging AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_duty_exchange AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_suppress_columns AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_multiple_formats AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_1st_shpmt_digits AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_post_date_def AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_disassembly AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_salesman_split AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_csld_regds AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_house_comm AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_grp2 AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_change_writeoff AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_salesman_quota AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_days_past_disc_date AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_self_mail_stmt AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_self_mail_gem AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_edi8111 AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cust_code AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_desc_seq AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_alt_entry AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_slm_restrict AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_def_inv_amount AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_stmt_discount AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ns_invoice_lock AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ord_hold AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_sales_tax_audit AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_variance_by_weight AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_alt_quote_comp AS LOGICAL NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_sales_regds AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_disp_by_host AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_paid_tax AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_disp_by_host_plus AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_custname_on_stub AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_po_invoice AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_low_check_number AS LOGICAL INIT no NO-UNDO.
DEF NEW  SHARED VAR g_pay_ext_cost AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_viewoptions_ar AS LOGICAL INIT no NO-UNDO.
DEF NEW  SHARED VAR g_terms_cutoff AS LOGICAL INIT NO NO-UNDO.
DEF NEW  SHARED VAR g_psi_order AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_job_tracking AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_mfr_rep_ords AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_dsassembly_ap AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_disp_frt_code AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_disp_carpro_flds AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_ds_swo AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_commission_zero AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_recv_comm_cost AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_tax_rpt_schd_br AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_no_zero_tax AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_90_and_over AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_apply_credits AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_show_credit_memos AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_net_cost_fnnl AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_rebate_journal AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_special_cost_basis AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_freight_in_cost AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_custpart AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_orddate AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_pro_carrier_dswhse AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_expense_checkreg AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_no_writeoff AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_clock_cell AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_order_writer AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_track_buying_groups AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_single_month_inv AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_dumping_multiplier AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_proj_track AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_proj_track_enable AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_po_acd AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_delin_notice_9c AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_no_parameter AS LOGICAL INIT no No-UNDO.
DEFINE NEW  SHARED VARIABLE g_full_page AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_factura AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_expjrnl_invdt AS LOGICAL INIT no NO-UNDO.  
DEFINE NEW  SHARED VARIABLE g_item_ticket AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_exclude_ds AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cash_counter AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_scrip_address2 AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_savepart AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_edit_cost AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_deductible_frt AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_catalog_source AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_one_chk_num AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_fc_accu_tax AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_specialist AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_cost_center_dc AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_balfwd_br AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_only_subs AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_add_month AS LOGICAL INIT no NO-UNDO.
DEF NEW  SHARED VAR g_lockbox2 AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_q_mode AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_no_servers AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_alt_gl_database AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_confidential as logical no-undo.
DEFINE NEW  SHARED VARIABLE g_system AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_length AS INTEGER INIT ? NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_p21_port AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_effective_port AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_report_name as char format "x(30)" NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_job as char format "x(10)" NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_credit_approved AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_protobase AS LOGICAL INIT no NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_exchange_date AS DATE INIT TODAY NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_exchange_time AS INTEGER INIT 0 NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_default_currency AS CHARACTER NO-UNDO.
DEF NEW  SHARED VAR g_salesman_commission AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_commission_cutoff AS INTEGER NO-UNDO INIT 0.
DEF NEW  SHARED VAR g_commission_negative AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_commission_partial AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_tax_ar AS LOGICAL NO-UNDO INIT NO.
DEFINE NEW  SHARED VARIABLE g_neg_check AS LOGICAL INIT NO NO-UNDO.
DEFINE NEW  SHARED VARIABLE g_comment_num AS LOGICAL NO-UNDO INIT FALSE.
DEF NEW  SHARED VAR g_fax              AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_forms           AS INTEGER NO-UNDO INIT 0.
DEF NEW  SHARED VAR g_fax_reform       AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_2nd_proc         AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_document_imaging AS INTEGER NO-UNDO INIT 0.
DEF NEW  SHARED VAR g_fnpq             AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_paymnt_plan_fpip  AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_commission_taker_rpt  AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_serv_main  AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_rentals AS LOGICAL NO-UNDO INIT NO. 
DEF NEW  SHARED VAR g_barcode AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_year_cost_update AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_welding AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_b2b AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_accl_sls_hist    AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_salecomp_fpro AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_univ_comm AS LOGICAL NO-UNDO INIT NO.
DEF NEW  SHARED VAR g_status_frame AS CHARACTER INIT ? NO-UNDO.
DEF NEW  SHARED VAR g_status_field AS CHARACTER INIT ? NO-UNDO.
DEF NEW  SHARED VAR g_status_index AS INTEGER INIT ? NO-UNDO.
DEF NEW  SHARED VAR g_line_length AS INTEGER INIT 78 NO-UNDO.
DEF NEW  SHARED VAR g_status_line AS CHARACTER INIT ? NO-UNDO.
DEF NEW  SHARED VAR g_have_mail AS INTEGER INIT ? NO-UNDO.
/* do: */
        assign g_status_frame = ?
               g_status_field = ?
               g_status_index = ?.
/* end
 . */
DEF NEW  SHARED VAR g_print_mode    AS INT  NO-UNDO INIT 1.
DEF NEW  SHARED VAR g_page_size     AS INT  NO-UNDO INIT -1.
DEF NEW  SHARED VAR g_parameters    AS LOG  NO-UNDO.
DEF NEW  SHARED VAR g_output_device AS CHAR NO-UNDO.
DEF NEW  SHARED VAR g_output_file   AS CHAR NO-UNDO.
DEF NEW  SHARED VAR g_save_to_cold AS LOG NO-UNDO INIT NO.
DEF NEW SHARED WORK-TABLE wt_print_options NO-UNDO
                FIELD printer_number AS INT INIT 1   
                FIELD print_mode AS INT              
                FIELD page_size AS INT               
                FIELD parameters AS LOG              
                FIELD param_pages AS INT             
                FIELD file_name AS CHAR              
                FIELD output_device AS CHAR          
    FIELD email_auto_address AS LOG INIT NO  
                FIELD fax_recip AS CHAR INIT ""      
                FIELD fax_comp AS CHAR INIT ""       
                FIELD fax_prefix AS CHAR INIT ""     
                FIELD fax_fax AS CHAR INIT ""        
                FIELD fax_subj AS CHAR INIT ""       
                FIELD fax_header AS CHAR INIT ""     
                FIELD fax_note AS CHAR INIT ""       
                FIELD fax_sender AS CHAR INIT ?      
                FIELD fax_name AS CHAR INIT ?        
                FIELD fax_addr AS CHAR INIT ?        
                FIELD fax_city AS CHAR INIT ?        
                FIELD fax_state AS CHAR INIT ?       
                FIELD fax_zip AS CHAR INIT ?         
                FIELD fax_lfax AS CHAR INIT ?        
                FIELD fax_ltel AS CHAR INIT ?        
                FIELD fax_time AS CHAR INIT ""       
                FIELD fax_form AS CHAR INIT ""       
                FIELD fax_reform AS CHAR INIT ""     
                FIELD fax_orient AS LOG INIT ?       
                FIELD fax_lpi AS INT INIT ?          
                FIELD fax_lpp AS INT INIT ?          
                FIELD fax_top AS INT INIT ?          
                FIELD fax_left AS INT INIT ?         
                FIELD include_cover AS LOGICAL INIT YES  
                FIELD fax_id AS INT                  
                FIELD fax_handle AS CHAR             
                FIELD fax_mail AS LOG INIT YES       
                FIELD fax_usid AS CHAR               
                FIELD fax_doctype AS CHAR            
                FIELD fax_docnum AS INT              
                FIELD fax_portnum AS INT             
                FIELD email_address AS CHAR INIT ""     
                FIELD html_title AS CHAR                 
                FIELD html_description AS CHAR          
                FIELD html_bgcolor AS CHAR               
                FIELD html_fgcolor AS CHAR               
                FIELD html_address AS CHAR               
                FIELD html_email AS CHAR                 
                FIELD html_image AS CHAR                 
                FIELD html_logo AS CHAR                  
                FIELD html_www AS CHAR                   
                FIELD html_filename AS CHAR              
                FIELD spool_descrip AS CHAR              
                FIELD spool_printer AS INT INIT 0        
                FIELD spool_priority AS INT INIT 0       
                FIELD spool_id AS INT INIT 0             
                FIELD spool_subseq AS INT INIT 0         
                FIELD spool_hold AS LOG INIT NO          
                FIELD spool_blankpgs AS INT INIT 0       
                FIELD spool_extras AS INT INIT 0         
                FIELD spool_pause AS LOG INIT NO         
                .
DEF NEW  SHARED STREAM g_o_stream.                         
DEF NEW  SHARED VAR    g_form_name AS CHARACTER NO-UNDO.   
DEF NEW  SHARED VAR g_doctype AS CHAR NO-UNDO.             
DEF NEW  SHARED VAR g_docnum AS INT NO-UNDO.               
DEF NEW  SHARED VAR g_fax_interact AS INT NO-UNDO.         
DEF NEW  SHARED VAR g_fax_cover AS INT NO-UNDO.            
 /* . */
 /* . */
def NEW shared var s_program as char
                format "x(15)" no-undo.
def NEW shared var s_frame as char
                format "x(30)" no-undo.
def NEW shared var s_db as char
                format "x(15)" no-undo.
def NEW shared var s_file as char
                format "x(15)" no-undo.
def NEW shared var s_field as char
                format "x(15)" no-undo.
def NEW shared var s_index as int
                format ">9" no-undo.
def NEW shared var s_page as int
                format ">9" no-undo.
def NEW shared var s_value as char no-undo.
def NEW shared var s_shadow as log no-undo
 .
def NEW shared workfile w_help_stack no-undo
                field help_id as dec
                field program as char
 .    
run lib/custfeat.p.
on  
'F1'
  "HELP".
on  
'PF1'
  "HELP".
on 'F2'
  "GO".
on 'PF2'
  "GO".
on 'F3'
  GET
 .
on 'PF3'
  GET
 .
on  
'F6' 
  "NEXT-FRAME".
on "CTRL-G" "NEXT-FRAME".
on  
'CTRL-R'
  "RECALL".
 /* . */
ON HELP ANYWHERE
DO:
  RUN p21/startup/help.p (                
    INPUT 3823                   
  ).
  RUN lib/status.p.
  RETURN NO-APPLY.
END.
def var procname as char.
find first p21.customer no-lock no-error.
if available(p21.customer) then put unformatted "OK" skip.
procname = "/home/amaltsev/current/" + OS-GETENV("PROCNAME") + ".p".
run value(procname).
put unformatted "OK" skip.
quit.
