*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTRODADO........................................*
DATA:  BEGIN OF STATUS_ZTRODADO                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTRODADO                      .
CONTROLS: TCTRL_ZTRODADO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTRODADO                      .
TABLES: ZTRODADO                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
