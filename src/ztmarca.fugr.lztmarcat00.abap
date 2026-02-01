*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTMARCA.........................................*
DATA:  BEGIN OF STATUS_ZTMARCA                       .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTMARCA                       .
CONTROLS: TCTRL_ZTMARCA
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTMARCA                       .
TABLES: ZTMARCA                        .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
