*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTMOBRA_SERV....................................*
DATA:  BEGIN OF STATUS_ZTMOBRA_SERV                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTMOBRA_SERV                  .
CONTROLS: TCTRL_ZTMOBRA_SERV
            TYPE TABLEVIEW USING SCREEN '0002'.
*...processing: ZTPARAM_COTSERV.................................*
DATA:  BEGIN OF STATUS_ZTPARAM_COTSERV               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPARAM_COTSERV               .
CONTROLS: TCTRL_ZTPARAM_COTSERV
            TYPE TABLEVIEW USING SCREEN '0004'.
*...processing: ZTPAUTA_SERV....................................*
DATA:  BEGIN OF STATUS_ZTPAUTA_SERV                  .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTPAUTA_SERV                  .
CONTROLS: TCTRL_ZTPAUTA_SERV
            TYPE TABLEVIEW USING SCREEN '0001'.
*...processing: ZTTEMPARIO_SERV.................................*
DATA:  BEGIN OF STATUS_ZTTEMPARIO_SERV               .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTTEMPARIO_SERV               .
CONTROLS: TCTRL_ZTTEMPARIO_SERV
            TYPE TABLEVIEW USING SCREEN '0003'.
*...processing: ZTTEXTOS_SERV...................................*
DATA:  BEGIN OF STATUS_ZTTEXTOS_SERV                 .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTTEXTOS_SERV                 .
CONTROLS: TCTRL_ZTTEXTOS_SERV
            TYPE TABLEVIEW USING SCREEN '0006'.
*.........table declarations:.................................*
TABLES: *ZTMOBRA_SERV                  .
TABLES: *ZTPARAM_COTSERV               .
TABLES: *ZTPAUTA_SERV                  .
TABLES: *ZTTEMPARIO_SERV               .
TABLES: *ZTTEXTOS_SERV                 .
TABLES: ZTMOBRA_SERV                   .
TABLES: ZTPARAM_COTSERV                .
TABLES: ZTPAUTA_SERV                   .
TABLES: ZTTEMPARIO_SERV                .
TABLES: ZTTEXTOS_SERV                  .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .
