*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTEQUIPO........................................*
DATA:  BEGIN OF STATUS_ZTEQUIPO                      .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTEQUIPO                      .
CONTROLS: TCTRL_ZTEQUIPO
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTEQUIPO                      .
TABLES: ZTEQUIPO                       .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
