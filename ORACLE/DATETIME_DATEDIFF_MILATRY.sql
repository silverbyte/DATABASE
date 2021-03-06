--MILATARY TIME
alter session set NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'

-- DATEDIFF DAYS HOURS MINUTES SECONDS
SELECT 
trunc(DATE1-DATE2) days,
mod( trunc( ( DATE1-DATE2 ) * 24 ), 24) HOURS,
mod( trunc( ( DATE1-DATE2 ) * 1440 ), 60 ) MINUTES,
mod( trunc( ( DATE1-DATE2 ) * 86400 ), 60 ) SECONDS
FROM dual;