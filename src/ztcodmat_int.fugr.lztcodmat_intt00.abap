*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTCODMAT_INT....................................*
DATA:  BEGIN OF STATUS_ZTCODMAT_INT                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTCODMAT_INT                  .
CONTROLS: TCTRL_ZTCODMAT_INT
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTCODMAT_INT                  .
TABLES: ZTCODMAT_INT                   .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
