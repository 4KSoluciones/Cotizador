*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTEXTOS_FIJOS...................................*
DATA:  BEGIN OF STATUS_ZTEXTOS_FIJOS                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTEXTOS_FIJOS                 .
CONTROLS: TCTRL_ZTEXTOS_FIJOS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTEXTOS_FIJOS                 .
TABLES: ZTEXTOS_FIJOS                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
