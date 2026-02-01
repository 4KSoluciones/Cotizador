*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO2......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO2                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO2                    .
CONTROLS: TCTRL_ZATRIBUTO2
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO2                    .
TABLES: ZATRIBUTO2                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
