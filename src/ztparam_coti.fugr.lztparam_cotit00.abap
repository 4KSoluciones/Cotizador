*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTPARAM_COTI....................................*
DATA:  BEGIN OF STATUS_ZTPARAM_COTI                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPARAM_COTI                  .
CONTROLS: TCTRL_ZTPARAM_COTI
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTPARAM_COTI                  .
TABLES: ZTPARAM_COTI                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
