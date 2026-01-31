ADD 1 TO v_pos.

CALL FUNCTION 'CONVERSION_EXIT_ALPHA_OUTPUT'
  EXPORTING
    input  = v_pos
  IMPORTING
    output = v_pos.

CLEAR v_texto.

CONCATENATE lw_textos-texto1
            lw_textos-texto2
            lw_textos-texto3
            lw_textos-texto4
            lw_textos-texto5
       INTO v_texto SEPARATED BY space.


















