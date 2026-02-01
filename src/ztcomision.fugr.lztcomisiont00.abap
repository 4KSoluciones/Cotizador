*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTCOMISION......................................*
DATA:  BEGIN OF STATUS_ZTCOMISION                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTCOMISION                    .
CONTROLS: TCTRL_ZTCOMISION
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTCOMISION                    .
TABLES: ZTCOMISION                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
