/*
 * Name:
 *	uspGetProductCode
 *
 * Purpose:
 *	This procedure uses RC4 to encrypt/decrypt the first parameter
 *  using the second parameter in the encryption key.
 *
 * Input Parameters:
 *	 @product     varchar(255) - The string to be encrypted/decrypted.
 *   @productCode varchar(32)  - The string key used to encrypt/decrypt.
 *
 * Output Parameters:
 *	  @productName varchar(255) - The encrypted/decrypted string.
 *
 * Returns:
 *  none
 *
 * DependsOn:
 *	none
 *
 * Calls:
 *	none
 *
 * Effects:
 *	none
 *
 * CalledBy:
 *	n/a
 *
 * History:
 *	   Date			Developer		Description
 *	-------------	------------	--------------------------------------
 *	01/22/2002		Brad Baker		Created procedure.
 *
 * Notes:
 *  1. RC4 is a stream cipher symmetric key algorithm.
 *     It was developed in 1987 by Ronald Rivest and kept as a trade secret by RSA Data Security.
 *     On September 9, 1994, the RC4 algorithm was anonymously posted on the Internet on the Cyperpunks’ “anonymous remailers” list. 
 *
 *  2. RC4 uses a variable length key from 1 to 256 bytes to initialize a 256-byte state table.
 *     The state table is used for subsequent generation of pseudo-random bytes and then to generate a pseudo-random stream which is XORed
 *     with the plaintext to give the ciphertext.
 *     Each element in the state table is swapped at least once.  
 *
 *  3. The RC4 key is often limited to 40 bits, because of export restrictions but it is sometimes used as a 128 bit key.
 *     It has the capability of using keys between 1 and 2048 bits.
 *     RC4 is used in many commercial software packages such as Lotus Notes and Oracle Secure SQL.
 *     It is also part of the Cellular Specification. 
 *
 * 	4. Procedure name and parameter names should be meaningless.
 *     Renaming this procedure RC4 would be very helpful to hackers.
 *
 *  5. This procedure should always be encrypted.
 *
 *	6. Since this procedure is used for both encryption and decryption,
 *     it is important to limit permissions to it.
 *
 * Example:
 * 	DECLARE
 *	 @encrypted varchar(255)
 *	EXEC uspGetProductCode 'mypassword', 'mykey', @encrypted OUTPUT
 */
ALTER PROCEDURE uspGetProductCode
 (@product     varchar(255),
  @productCode varchar(32),
  @productName varchar(255) OUTPUT)
WITH ENCRYPTION
AS
-- Eliminate rowcount messages.
SET NOCOUNT ON
-- Declare variables.
DECLARE
	@state smallint,
	@key  smallint,
	@tempSwap smallint,
	@a smallint,
	@b smallint,
	@N smallint,
	@temp smallint,
	@i smallint,
	@j smallint,
	@k smallint,
	@cipherby smallint,
	@cipher varchar(255),
	@code   varchar(64)

	-- The RC4 algorithm works in two phases, key setup and ciphering.
	-- Key setup is the first and most difficult phase of this algorithm.
	-- During a N-bit key setup (N being your key length),
	--  the encryption key is used to generate an encrypting variable using two arrays,
	--  state and key, and N-number of mixing operations.
	--  These mixing operations consist of swapping bytes,
	--   modulo operations, and other formulas.
	--  A modulo operation is the process of yielding a remainder from division.
	-- This implementation of RC4 uses temporary tables in place of arrays.
	CREATE TABLE #Keys
	(
		ID    smallint ,
		state  smallint ,
		intKey  smallint
	)
	-- Initialize variable values.
	SET @code = @productcode + ',./;''p[\`0-=Z<?L:"P{|~!@#%^*(_'
	SELECT
	 @N = Len(@code),
	 @a = 0
	-- Initialize temp table with key and state values.
	WHILE @a < 256
	BEGIN
		SELECT
		 @key = Ascii(Substring(@code, (@a%@N) + 1, 1)),
		 @state = @a
		INSERT #Keys(ID, state, intKey) VALUES(@a, @state, @key)
		SET @a = @a + 1
	END

	-- Initialize variable values.
	SELECT
	 @b = 0,
	 @a = 0
    -- The state array now undergoes 256 mixing operations.
	WHILE @a < 256
	BEGIN
		SELECT @b = (@b + state + intKey) % 256, @tempSwap = state 
		FROM #Keys 
		WHERE ID = @a
		UPDATE #Keys 
		SET state = (SELECT state FROM #Keys WHERE ID = @b) 
		WHERE ID = @a
		UPDATE #Keys 
		SET state = @tempSwap 
		WHERE ID = @b
		SET @a = @a + 1
	END

	-- Initialize variable values.
	SELECT
	 @i = 0,
	 @j = 0,
	 @a = 1,
	 @cipher = '',
	 @cipherby = 0

	-- Once the encrypting variable is produced from the key setup,
	--  it enters the ciphering phase,
	--  where it is XORed with the plain text message to create and encrypted message.
	--  XOR is the logical operation of comparing two binary bits.
	--  If the bits are different, the result is 1.
	--  If the bits are the same, the result is 0.
	--  The string is decrypted by XORing the encrypted message with the same encrypting key. 
	WHILE @a < Len(@product) + 1
	BEGIN
		SET 
		SELECT
		 @i = (@i + 1) % 256,
		 @j = (@j + state) % 256,
		 @temp = state
		FROM #Keys 
		WHERE ID = @i
		UPDATE #Keys 
		SET state = (SELECT state FROM #Keys WHERE ID = @j) 
		WHERE ID = @i
		UPDATE #Keys 
		SET state = @temp 
		WHERE ID = @j
		SELECT @k = state 
		FROM #Keys 
		WHERE ID = (((SELECT state FROM #Keys WHERE ID = @i) + (SELECT state FROM #Keys WHERE ID = @j)) % 256)
		SET @cipherby = Ascii(Substring(@product, @a, 1)) ^ @k
		SET @cipher = @cipher + Char(@cipherby)
		SET @a = @a + 1
	END

	-- Clean up.
	DROP TABLE #Keys
	-- Set ouput variable.
	SET @productName = @cipher
	SET NOCOUNT OFF
