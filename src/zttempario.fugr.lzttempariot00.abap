*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTTEMPARIO......................................*
DATA:  BEGIN OF STATUS_ZTTEMPARIO                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTTEMPARIO                    .
CONTROLS: TCTRL_ZTTEMPARIO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTTEMPARIO                    .
TABLES: ZTTEMPARIO                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
