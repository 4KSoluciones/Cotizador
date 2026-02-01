PROCESS BEFORE OUTPUT.
  MODULE status_9000.
  MODULE textos_9000.

PROCESS AFTER INPUT.
  MODULE exit_command_9000 AT EXIT-COMMAND.
  MODULE user_command_9000.

PROCESS ON VALUE-REQUEST.
  FIELD: wa_screen1-equipo      MODULE f4_equipo,
         wa_screen1-marca       MODULE f4_marca,
         wa_screen1-modelo      MODULE f4_modelo,
         wa_screen1-modalidad   MODULE f4_modalidad,
         wa_screen1-sucursal    MODULE f4_sucursal,
         wa_screen1-lugar       MODULE f4_lugar,
         wa_screen1-caja        MODULE f4_caja,
         wa_screen1-diferencial MODULE f4_diferencial.
