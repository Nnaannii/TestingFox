PRINT '--------------------------------------------------------------------------------------'
PRINT ' Insert Configuration for for On line CK route				             '
PRINT ' 		 							             '
PRINT ' For eFox - 0311									     '
PRINT '--------------------------------------------------------------------------------------'
PRINT ''

DECLARE @m_strControlName	VARCHAR(50),
	@m_strPlantID			VARCHAR(20),
	@m_strControlValue		VARCHAR(100),
	@m_strControlType		CHAR(8),
	@m_strControlLevel		CHAR(1),
	@m_strControlDesc		VARCHAR(255),
	@m_nControlSeqno		INT,
	@m_strUserName			VARCHAR(20),
	@m_bAbort				BIT,
	@m_bDeleteOldData		BIT,
	@m_InsertData			BIT,
	@m_nShowUpdateResult	INT,
	@m_intSeqNo				INT


----- PLEASE MAKE SURE THE SETTING IS RIGHT -----
SET @m_strUserName	= 'SYSTEM'
SET @m_intSeqNo		= 0
SET @m_bDeleteOldData	= 0
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
--cPC
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp cPC PRODUCTION PHASE II')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('JZ cPC BenchMark DB')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp cPC TEST') 

--select * from econtrolvalue(nolock)where controlname = 'DATABASE_TYPE'
IF NOT EXISTS (SELECT 1 FROM econtrolvalue a (NOLOCK), @table_DatabaseType b WHERE a.controlname = 'DATABASE_TYPE' and a.controlvalue=b.controlvalue)
BEGIN
	PRINT 'This script has not been configured to run against this DB... ABORTING!'
	RETURN
END

DECLARE @table_eControlValue TABLE
(
	[CONTROLNAME] [varchar] (50)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CONTROLVALUE] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[CONTROLTYPE] [char](8) NULL ,
	[CONTROLLEVEL] [char] (1)  NULL ,
	[CONTROLDESC] [varchar] (255)  NULL ,
	[controlseqno] [int]   NULL ,
	[LUPBY] [nvarchar] (20)  NULL ,
	[LUPDATE] [datetime] NULL,
	[rowid] INT IDENTITY 
)

------------------------------------------------------------------------------------------

SET @m_intSeqNo = 0
SET @m_intSeqNo = @m_intSeqNo + 10

INSERT @table_eControlValue(CONTROLNAME,CONTROLVALUE,CONTROLTYPE,CONTROLLEVEL,CONTROLDESC,controlseqno,LUPBY,LUPDATE)
	VALUES('WO-CHECKTOOL-INVALID-MT','ZFRT','MULTIPLE','0','valid material types for keypart components',@m_intSeqNo,@m_strUserName, GETDATE())
			
SET @m_intSeqNo = @m_intSeqNo + 10
INSERT @table_eControlValue(CONTROLNAME,CONTROLVALUE,CONTROLTYPE,CONTROLLEVEL,CONTROLDESC,controlseqno,LUPBY,LUPDATE)
	VALUES('WO-CHECKTOOL-INVALID-MT','ZWAR','MULTIPLE','0','valid material types for keypart components',@m_intSeqNo,@m_strUserName, GETDATE())
			
SET @m_intSeqNo = @m_intSeqNo + 10
INSERT @table_eControlValue(CONTROLNAME,CONTROLVALUE,CONTROLTYPE,CONTROLLEVEL,CONTROLDESC,controlseqno,LUPBY,LUPDATE)
	VALUES('WO-CHECKTOOL-INVALID-MT','ZMOD','MULTIPLE','0','valid material types for keypart components',@m_intSeqNo,@m_strUserName, GETDATE())

--select * from econtrolvalue(nolock)where controlvalue = 'countrykit3'
      
     ------------------------------------------------------------------------------------------


BEGIN TRANSACTION econtrolvalue_data
/*
IF @m_bDeleteOldData = 1
BEGIN
	DELETE FROM econtrolvalue WHERE controlname IN (SELECT controlname FROM @table_eControlValue WHERE CONTROLTYPE='SINGLE')

	DELETE econtrolvalue
	FROM econtrolvalue as a, @table_eControlValue as b
	WHERE B.CONTROLTYPE='MULTIPLE' AND b.controlname=a.controlname AND b.controlvalue=a.controlvalue
END
*/

IF @m_InsertData = 1
begin
	declare @count int,
		@totcount int
	set @count =1
	set @totcount = 0 

	select top 1 @totcount = rowid from @table_eControlValue order by rowid desc
	while @count <= @totcount
	begin
		if exists (select 0 from econtrolvalue a(nolock), @table_eControlValue b where a.controlname = b.controlname and b.CONTROLTYPE = 'SINGLE' and rowid =@count )
		begin
			update econtrolvalue with (rowlock)
			set CONTROLNAME   = b.CONTROLNAME
				,CONTROLVALUE  = b.CONTROLVALUE
				,CONTROLTYPE   = b.CONTROLTYPE
				,CONTROLLEVEL  = b.CONTROLLEVEL
				,CONTROLDESC   = b.CONTROLDESC
				,controlseqno  = b.controlseqno
				,LUPBY         = b.LUPBY
				,LUPDATE       = b.LUPDATE
			from econtrolvalue a(nolock), @table_eControlValue b where a.controlname = b.controlname and b.CONTROLTYPE = 'SINGLE'  and rowid =@count
		end
		else
		begin
			if not exists(select 0 from econtrolvalue a(nolock), @table_eControlValue b where a.controlname = b.controlname 
				and a.controlvalue= b.controlvalue and b.CONTROLTYPE = 'MULTIPLE' and rowid =@count )
			begin
				INSERT INTO econtrolvalue WITH (ROWLOCK) 
				SELECT CONTROLNAME,CONTROLVALUE,CONTROLTYPE,CONTROLLEVEL,CONTROLDESC,controlseqno,LUPBY,LUPDATE FROM @table_eControlValue where rowid =@count
			end
		end	
		set @count = @count +1
	end
end
--rollback
COMMIT TRANSACTION

IF @m_nShowUpdateResult = 1

	SELECT * FROM econtrolvalue (NOLOCK) WHERE controlname IN (SELECT controlname FROM @table_eControlValue)

ELSE
	SELECT * FROM @table_eControlValue

