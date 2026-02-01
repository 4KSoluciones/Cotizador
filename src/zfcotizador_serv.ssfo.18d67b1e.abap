
CLEAR v_sucursal.

SELECT SINGLE bezei
  FROM tvkbt
  INTO v_sucursal
 WHERE spras = 'S'
   AND vkbur = wa_cotizacion-sucursal.























