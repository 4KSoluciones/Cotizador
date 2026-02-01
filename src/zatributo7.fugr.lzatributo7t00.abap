*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO7......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO7                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO7                    .
CONTROLS: TCTRL_ZATRIBUTO7
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO7                    .
TABLES: ZATRIBUTO7                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
