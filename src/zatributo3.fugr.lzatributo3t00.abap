*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZATRIBUTO3......................................*
DATA:  BEGIN OF STATUS_ZATRIBUTO3                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZATRIBUTO3                    .
CONTROLS: TCTRL_ZATRIBUTO3
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZATRIBUTO3                    .
TABLES: ZATRIBUTO3                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
