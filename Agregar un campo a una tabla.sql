
PRINT '--------------------------------------------------------------------------------------'
PRINT ' Insert new column on MFWORKORDER for Change Dismantle Process					             '
PRINT ' For eFox - S311	bPC																	 '
PRINT '--------------------------------------------------------------------------------------'
PRINT ''


DECLARE @dbname AS varchar(20)

SET @dbname = DB_NAME()

DECLARE @m_strControlName		VARCHAR(50),
	@m_strPlantID			VARCHAR(20),
	@m_strControlValue		VARCHAR(100),
	@m_strControlType		CHAR(8),
	@m_strControlLevel		CHAR(1),
	@m_strControlDesc		VARCHAR(255),
	@m_nControlSeqno	INT,
	@m_strUserName			VARCHAR(20),

	@m_bAbort		BIT,
	@m_bDeleteOldData	BIT,
	@m_InsertData		BIT,
	@m_nShowUpdateResult	INT,
	@m_intSeqNo		INT


----- PLEASE MAKE SURE THE SETTING IS RIGHT -----
SET @m_strUserName	= 'SYSTEM'
SET @m_intSeqNo		= 0
SET @m_bDeleteOldData	= 1
SET @m_InsertData	= 1
SET @m_nShowUpdateResult= 1
-------------------------------------------------

----- DONN'T MODIFY -----
SET @m_bAbort = 0
-------------------------
SELECT @m_strPlantID = controlvalue FROM econtrolvalue (NOLOCK) WHERE controlname = 'DEFAULT FACTORY ID'
SET @m_strPlantID = ISNULL(@m_strPlantID, '')
IF @m_strPlantID = ''
BEGIN
	PRINT 'The DEFAULT FACTORY ID of current DB is empty!'
	SET @m_bAbort = 1	
END

IF @m_strPlantID not in ('S311')
BEGIN
	PRINT	'The DEFAULT FACTORY ID of current DB is not S311 site!'
	SET @m_bAbort = 1
END

IF LEN(@m_strUserName) = 0
BEGIN
	PRINT	'Please setting a valid User Name!'
	SET @m_bAbort = 1
END

IF @m_bAbort = 1 
	RETURN

DECLARE @table_DatabaseType TABLE
(
	[CONTROLVALUE] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)

--Configure the DBs that this script file can be run against.
--BPC
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp TEST PHASE II')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('JZ bPC BenchMark DB')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp  PRODUCTION Phase II')


IF NOT EXISTS (SELECT 1 FROM econtrolvalue a (NOLOCK), @table_DatabaseType b WHERE a.controlname = 'DATABASE_TYPE' and a.controlvalue=b.controlvalue)
BEGIN
	PRINT 'This script has not been configured to run against this DB... ABORTING!'
	RETURN
END

	IF NOT EXISTS ( SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_CATALOG = @dbname AND TABLE_NAME = 'MFWORKORDER' AND COLUMN_NAME IN 
	('PreCancelled'))
	BEGIN
		ALTER TABLE MFWORKORDER ADD [PreCancelled] [BIT]  DEFAULT (0)
		
		PRINT 'MFWORKORDER Has Been Altered with new columns.'

		exec('UPDATE MFWORKORDER WITH (ROWLOCK) SET PreCancelled =0 ')
	END
	ELSE
	BEGIN
		PRINT 'Could Not Alter MFWORKORDER Because some Column Would Be Duplicated!!'
	END



