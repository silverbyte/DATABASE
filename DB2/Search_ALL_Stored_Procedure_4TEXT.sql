select ROUTINENAME, TEXT from syscat.routines
where 
  /*
  definer not in ('SYSIBM') 
  AND 
  ROUTINESCHEMA='TMWIN' 
  and 
  */
  TEXT  LIKE '%CALC_DGTEMP%'
ORDER BY ROUTINENAME

