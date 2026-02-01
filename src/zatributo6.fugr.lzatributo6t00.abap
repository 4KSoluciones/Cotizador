*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO6......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO6                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO6                    .
CONTROLS: TCTRL_ZATRIBUTO6
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO6                    .
TABLES: ZATRIBUTO6                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
