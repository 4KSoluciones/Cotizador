*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTPAUTA.........................................*
DATA:  BEGIN OF STATUS_ZTPAUTA                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPAUTA                       .
CONTROLS: TCTRL_ZTPAUTA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTPAUTA                       .
TABLES: ZTPAUTA                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
