/* Formatted on 15/01/2012 22:52:55 (QP5 v5.139.911.3011) */
--DROP TYPE MSTR_LNKD_GROUP_ROW_TYPE;

CREATE OR REPLACE TYPE mstr_goog_adata_row_type AS OBJECT
   (country VARCHAR2 (500),
    browser VARCHAR2 (500),
    source VARCHAR2 (2000),
    visits NUMBER,
    pageviews NUMBER,
    timeOnSite NUMBER,
    exits NUMBER);
/