*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTMANODEOBRA....................................*
DATA:  BEGIN OF STATUS_ZTMANODEOBRA                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTMANODEOBRA                  .
CONTROLS: TCTRL_ZTMANODEOBRA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTMANODEOBRA                  .
TABLES: ZTMANODEOBRA                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
