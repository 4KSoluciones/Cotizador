
SELECT tipo descripcion valor1 valor2 valor3 valor4
  INTO TABLE gt_adicionales
  FROM ZTPARAM_COTSERV
 WHERE tipo LIKE 'ADICIONAL%'
   AND equipo = space. "wa_cotizacion-equipo

IF sy-subrc = 0.
  SORT gt_adicionales BY tipo_dto.
ENDIF.




















