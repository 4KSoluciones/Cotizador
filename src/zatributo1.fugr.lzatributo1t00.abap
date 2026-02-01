*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO1......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO1                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO1                    .
CONTROLS: TCTRL_ZATRIBUTO1
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO1                    .
TABLES: ZATRIBUTO1                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
