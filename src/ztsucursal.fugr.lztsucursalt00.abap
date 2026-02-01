*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTSUCURSAL......................................*
DATA:  BEGIN OF STATUS_ZTSUCURSAL                    .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTSUCURSAL                    .
CONTROLS: TCTRL_ZTSUCURSAL
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTSUCURSAL                    .
TABLES: ZTSUCURSAL                     .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
