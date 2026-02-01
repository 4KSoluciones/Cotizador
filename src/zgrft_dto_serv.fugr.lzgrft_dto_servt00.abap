*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTDTO_SERV_MANT.................................*
DATA:  BEGIN OF STATUS_ZTDTO_SERV_MANT               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTDTO_SERV_MANT               .
CONTROLS: TCTRL_ZTDTO_SERV_MANT
            TYPE TABLEVIEW USING SCREEN '0001'.
*.........table declarations:.................................*
TABLES: *ZTDTO_SERV_MANT               .
TABLES: ZTDTO_SERV_MANT                .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
