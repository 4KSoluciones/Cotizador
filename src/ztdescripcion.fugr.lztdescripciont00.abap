*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTDESCRIPCION...................................*
DATA:  BEGIN OF STATUS_ZTDESCRIPCION                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTDESCRIPCION                 .
CONTROLS: TCTRL_ZTDESCRIPCION
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTDESCRIPCION                 .
TABLES: ZTDESCRIPCION                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
