IF wa_cotizacion-chk_uso_ajus = 'X'.

  CONCATENATE '$' wa_cotizacion-val_kmhs_ajus1 INTO vl_hs1 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs_ajus2 INTO vl_hs2 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs_ajus3 INTO vl_hs3 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs_ajus4 INTO vl_hs4 SEPARATED BY space.

ELSE.

  CONCATENATE '$' wa_cotizacion-val_kmhs1 INTO vl_hs1 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs2 INTO vl_hs2 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs3 INTO vl_hs3 SEPARATED BY space.
  CONCATENATE '$' wa_cotizacion-val_kmhs4 INTO vl_hs4 SEPARATED BY space.

ENDIF.
