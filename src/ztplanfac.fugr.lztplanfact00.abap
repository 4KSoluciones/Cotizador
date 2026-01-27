*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTPLANFAC.......................................*
DATA:  BEGIN OF STATUS_ZTPLANFAC                     .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPLANFAC                     .
CONTROLS: TCTRL_ZTPLANFAC
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTPLANFAC                     .
TABLES: ZTPLANFAC                      .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
