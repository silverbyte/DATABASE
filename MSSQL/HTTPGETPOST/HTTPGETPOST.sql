	
--check security config
EXEC sp_configure 'Ole Automation Procedures';
GO
--enable security config
sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'Ole Automation Procedures', 1;
GO
RECONFIGURE;
GO


---HTTP GET 
DECLARE @status int
DECLARE @responseText as table(responseText nvarchar(max))
DECLARE @res as Int;
DECLARE @url as nvarchar(1000) = 'https://api.transplus.ca/bookingstatus/LT943995'
EXEC sp_OACreate 'MSXML2.ServerXMLHTTP', @res OUT
EXEC sp_OAMethod @res, 'open', NULL, 'GET',@url,'false'
EXEC sp_OAMethod @res, 'send'
EXEC sp_OAGetProperty @res, 'status', @status OUT
INSERT INTO @ResponseText (ResponseText) EXEC sp_OAGetProperty @res, 'responseText'
EXEC sp_OADestroy @res
SELECT @status, responseText FROM @responseText
	

--HTTP POST example 1
-- NOTE: if the post reply is larger than 8000 characters then response will be null.
-- will only work with post reply less than 8K 
-- check example 2 for URI example to test
DECLARE @status int
DECLARE @res AS INT;
DECLARE @ResponseText AS VARCHAR(8000);
DECLARE @Body AS VARCHAR(8000) = 
'{
    "docid": "Syn3159187",
    "filetype": "tif"
}'  
EXEC sp_OACreate 'MSXML2.XMLHTTP', @res OUT;
EXEC sp_OAMethod @res, 'open', NULL, 'post','https://api.transplus.com/getDoc/', 'false'
EXEC sp_OAMethod @res, 'setRequestHeader', null, 'Content-Type', 'application/json'
EXEC sp_OAMethod @res, 'send', null, @body
EXEC sp_OAMethod @res, 'responseText', @ResponseText OUTPUT
EXEC sp_OAGetProperty @res, 'status', @status OUT
--SELECT @status, @ResponseText, @body
PRINT 'Status: ' + str(@status) ;
PRINT 'Response text: ' + @responseText;

EXEC sp_OADestroy @res


------------------------------------------------------------------------------------

--HTTP POST example 2
-- adds authentication header
-- limit response on varchar (####) 
-- varchar(max) doesn't work, below test API working

DECLARE @authHeader NVARCHAR(64);
DECLARE @contentType NVARCHAR(64);
DECLARE @postData NVARCHAR(2000);
DECLARE @responseText NVARCHAR(4000);
DECLARE @responseXML NVARCHAR(4000);
DECLARE @ret INT;
DECLARE @status NVARCHAR(32);
DECLARE @statusText NVARCHAR(32);
DECLARE @token INT;
DECLARE @url NVARCHAR(256);

--SET @authHeader = 'BASIC 0123456789ABCDEF0123456789ABCDEF';
SET @contentType = 'application/json';
SET @postData = '{
  "Id": 78912,
  "Customer": "Jason Sweet",
  "Quantity": 1,
  "Price": 18.00
}';
SET @url = 'https://reqbin.com/echo/post/json';

-- Open the connection.
EXEC @ret = sp_OACreate 'MSXML2.ServerXMLHTTP', @token OUT;
IF @ret <> 0 RAISERROR('Unable to open HTTP connection.', 10, 1);

-- Send the request.
EXEC @ret = sp_OAMethod @token, 'open', NULL, 'POST', @url, 'false';
--EXEC @ret = sp_OAMethod @token, 'setRequestHeader', NULL, 'Authentication', @authHeader;
EXEC @ret = sp_OAMethod @token, 'setRequestHeader', NULL, 'Content-type', @contentType;
EXEC @ret = sp_OAMethod @token, 'send', NULL, @postData;

-- Handle the response.
EXEC @ret = sp_OAGetProperty @token, 'status', @status OUT;
EXEC @ret = sp_OAGetProperty @token, 'statusText', @statusText OUT;
EXEC @ret = sp_OAGetProperty @token, 'responseText', @responseText OUT;

-- Show the response.
PRINT 'Status: ' + @status + ' (' + @statusText + ')';
PRINT 'Response text: ' + @responseText;

-- Close the connection.
EXEC @ret = sp_OADestroy @token;
IF @ret <> 0 RAISERROR('Unable to close HTTP connection.', 10, 1);
