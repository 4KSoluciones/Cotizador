PROCESS BEFORE OUTPUT.
  MODULE status_0300.

PROCESS AFTER INPUT.
  MODULE user_command_0300.

PROCESS ON VALUE-REQUEST.
  FIELD: v_cliente   MODULE f4_nrocotiz,
         v_fecha     MODULE f4_nrocotiz,
         v_nrocotiz  MODULE f4_nrocotiz,
         v_version   MODULE f4_nrocotiz.
