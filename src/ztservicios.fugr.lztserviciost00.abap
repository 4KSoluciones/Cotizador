*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTSERVICIOS.....................................*
DATA:  BEGIN OF STATUS_ZTSERVICIOS                   .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTSERVICIOS                   .
CONTROLS: TCTRL_ZTSERVICIOS
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTSERVICIOS                   .
TABLES: ZTSERVICIOS                    .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
