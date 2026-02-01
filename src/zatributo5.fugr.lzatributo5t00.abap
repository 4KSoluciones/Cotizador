*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO5......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO5                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO5                    .
CONTROLS: TCTRL_ZATRIBUTO5
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO5                    .
TABLES: ZATRIBUTO5                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
