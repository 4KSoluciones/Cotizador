*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTVALOR_CONTRATO................................*
DATA:  BEGIN OF STATUS_ZTVALOR_CONTRATO              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTVALOR_CONTRATO              .
CONTROLS: TCTRL_ZTVALOR_CONTRATO
            TYPE TABLEVIEW USING SCREEN '0002'.
*.........table declarations:.................................*
TABLES: *ZTVALOR_CONTRATO              .
TABLES: ZTVALOR_CONTRATO               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
