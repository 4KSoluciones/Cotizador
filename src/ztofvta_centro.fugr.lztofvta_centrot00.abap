*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTOFVTA_CENTRO..................................*
DATA:  BEGIN OF STATUS_ZTOFVTA_CENTRO                .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTOFVTA_CENTRO                .
CONTROLS: TCTRL_ZTOFVTA_CENTRO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTOFVTA_CENTRO                .
TABLES: ZTOFVTA_CENTRO                 .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
