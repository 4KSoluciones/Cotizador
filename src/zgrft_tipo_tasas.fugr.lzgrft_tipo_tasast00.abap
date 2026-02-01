*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTTASAS.........................................*
DATA:  BEGIN OF STATUS_ZTTASAS                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTTASAS                       .
CONTROLS: TCTRL_ZTTASAS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTTASAS                       .
TABLES: ZTTASAS                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
