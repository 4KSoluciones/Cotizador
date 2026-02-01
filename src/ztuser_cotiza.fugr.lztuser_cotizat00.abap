*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTUSER_COTIZA...................................*
DATA:  BEGIN OF STATUS_ZTUSER_COTIZA                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTUSER_COTIZA                 .
CONTROLS: TCTRL_ZTUSER_COTIZA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTUSER_COTIZA                 .
TABLES: ZTUSER_COTIZA                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
