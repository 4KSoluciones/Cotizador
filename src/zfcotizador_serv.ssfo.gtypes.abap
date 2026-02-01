TYPES: ZTTEXTO TYPE STANDARD TABLE OF ZTTEXTOS_SERV.

TYPES: BEGIN OF ty_adicionales,
         tipo_dto TYPE ZTPARAM_COTSERV-tipo,
         texto    TYPE ZTPARAM_COTSERV-descripcion,
         col_1    TYPE ZTPARAM_COTSERV-valor1,
         col_2    TYPE ZTPARAM_COTSERV-valor2,
         col_3    TYPE ZTPARAM_COTSERV-valor3,
         col_4    TYPE ZTPARAM_COTSERV-valor4,
       END OF ty_adicionales,
       tyt_adicionales TYPE STANDARD TABLE OF ty_adicionales.


















