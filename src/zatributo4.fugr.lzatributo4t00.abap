*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO4......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO4                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO4                    .
CONTROLS: TCTRL_ZATRIBUTO4
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO4                    .
TABLES: ZATRIBUTO4                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
