/*
Using UTL_SMTP to send email with text/HTML as content. 
**You can use UTL_MAIL with mime type text/HTML but error code when using smtp-relay.gmail.com

Note: to send email as HTML you need to :  CALL UTL_SMTP.WRITE_DATA(v_conn, 'content-type: text/html;' || v_crlf); 

    CALL JC_SENDMAIL (
    '<'|| vEMAILFROM ||'>', --FROM
    '<'|| vEMAILTO ||'>',   --TO
    vEMAILSUBJECT,          --SUBJECT
    vEMAILMESSAGE,          --MESSAGE
    'smtp-relay.gmail.com');  --MAILHOST
*/

CREATE OR REPLACE PROCEDURE TMWIN.JC_SENDMAIL (
    IN P_SENDER	VARCHAR(4096),
    IN P_RECIPIENT	VARCHAR(4096),
    IN P_SUBJ	VARCHAR(4096),
    IN P_MSG	VARCHAR(4096),
    IN P_MAILHOST	VARCHAR(4096) )
  SPECIFIC SEND_MAIL_2
  LANGUAGE SQL
  NOT DETERMINISTIC
  EXTERNAL ACTION
  MODIFIES SQL DATA
  CALLED ON NULL INPUT
  INHERIT SPECIAL REGISTERS
  OLD SAVEPOINT LEVEL
BEGIN
  DECLARE v_conn UTL_SMTP.CONNECTION;
  DECLARE v_crlf VARCHAR(2);
  DECLARE v_port INTEGER CONSTANT 25;

  SET v_crlf = CHR(13) || CHR(10);
  SET v_conn = UTL_SMTP.OPEN_CONNECTION(p_mailhost, v_port, 10);
  CALL UTL_SMTP.HELO(v_conn, p_mailhost);
  CALL UTL_SMTP.MAIL(v_conn, p_sender);
  CALL UTL_SMTP.RCPT(v_conn, p_recipient);
  CALL UTL_SMTP.RCPT(v_conn, '<joe@trans-plus.com>');
  CALL UTL_SMTP.OPEN_DATA(v_conn);
  CALL UTL_SMTP.WRITE_DATA(v_conn, 'From: ' || p_sender || v_crlf);
  CALL UTL_SMTP.WRITE_DATA(v_conn, 'To: ' || p_recipient || v_crlf);
  CALL UTL_SMTP.WRITE_DATA(v_conn, 'Subject: ' || p_subj || v_crlf);
  CALL UTL_SMTP.WRITE_DATA(v_conn, 'content-type: text/html;' || v_crlf);  
  CALL UTL_SMTP.WRITE_DATA(v_conn, p_msg);
  CALL UTL_SMTP.CLOSE_DATA(v_conn);
  CALL UTL_SMTP.QUIT(v_conn);
END;
