
SELECT tipo descripcion valor1 valor2 valor3 valor4
  INTO TABLE gt_adicionales
  FROM ztparam_coti
 WHERE tipo   = 'ADICIONAL'
   AND opcion = wa_cotizacion-equipo.

IF sy-subrc = 0.
  SORT gt_adicionales BY tipo_dto.
ELSE.
  SELECT tipo descripcion valor1 valor2 valor3 valor4
    INTO TABLE gt_adicionales
    FROM ztparam_coti
   WHERE tipo   = 'ADICIONAL'.
  IF sy-subrc = 0.
    SORT gt_adicionales BY tipo_dto.
  ENDIF.
ENDIF.


















