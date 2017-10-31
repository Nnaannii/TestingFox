PRINT '-----------------------------------------------------------------------------------------------'
PRINT ' Insert Production Station Config Create a BIOS Check station in SFC	                      '
PRINT ' For eFoxSFC Juarez									      '
PRINT '-----------------------------------------------------------------------------------------------'
PRINT ''

DECLARE @m_strPlantID		VARCHAR(20),
	@m_strUserName		VARCHAR(30),
	@m_strRouteID		VARCHAR(30),

	@m_bAbort		BIT,
	@m_bDeleteOldData	BIT,
	@m_InsertData		BIT,
	@m_nShowUpdateResult	INT,

	@m_nIndex 		INT


----- PLEASE MAKE SURE THE SETTING IS RIGHT -----
SET @m_strUserName	= 'SYSTEM'
SET @m_strRouteID 	= ''
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

IF @m_strPlantID <> 'PEU6'
BEGIN
	PRINT	'The DEFAULT FACTORY ID of current DB is not PEU6 site!'
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
--eFox
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('NC EMC eFoxSFC DEV')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('EMCeFoxSFC')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('UAT_EMCeFoxSFC')
--select * from econtrolvalue(nolock)where controlname = 'DATABASE_TYPE'

IF NOT EXISTS (SELECT 1 FROM econtrolvalue a (NOLOCK), @table_DatabaseType b WHERE a.controlname = 'DATABASE_TYPE' and a.controlvalue=b.controlvalue)
BEGIN
	PRINT 'This script has not been configured to run against this DB... ABORTING!'
	RETURN
END

DECLARE @table_sfctaskmain TABLE
(
	[eventpoint] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[eventdesc] [varchar] (100)  NULL ,
	[createdate] [datetime] NULL ,
	[createby] [varchar] (20)  NULL ,
	[collectcount] [bit] NOT NULL ,
	[disabled] [bit] NOT NULL ,
	[note] [varchar] (255)  NULL ,
	[formname] [varchar] (20)  NULL ,
	[field1] [varchar] (20)  NULL ,
	[field2] [varchar] (20)  NULL ,
	[passcode] [varchar] (20)  NULL ,
	[failcode] [varchar] (20)  NULL ,
	[nopassfailaction] [bit] NULL ,
	[lasteditby] [varchar] (20)  NULL ,
	[lasteditdt] [datetime] NULL ,
	[beforewhid] [varchar] (20)  NULL ,
	[afterwhid] [varchar] (20)  NULL ,
	[eventtype] [varchar] (20)  NULL,
	[rowid] INT IDENTITY
)

--------------------------- Production Station ----------------------------------------------------------------------------------------------------------------
INSERT @table_sfctaskmain(eventpoint,eventdesc,createdate,createby,collectcount,disabled,note,formname,field1,field2,passcode,failcode,nopassfailaction,lasteditby,lasteditdt,beforewhid,afterwhid,eventtype)
	VALUES ('CHECK_BIOS','CHECK_BIOS',GETDATE(),@m_strUserName,1,0,'','SSNAUDIT','','','PASS','FAIL',0,@m_strUserName,GETDATE(),'RAID_CONFIG','VI','')
---------------------------------------------------------------------------------------------------------------------------------------------------------------


BEGIN TRANSACTION sfcroutedefb_data 
IF @m_InsertData = 1
begin
	declare @count int,
		@totcount int
	set @count =1
	set @totcount = 0 

	select top 1 @totcount = rowid from @table_sfctaskmain order by rowid desc
	while @count <= @totcount
	begin
		if exists(select 0 from sfctaskmain a(nolock), @table_sfctaskmain b where a.eventpoint = b.eventpoint and b.rowid = @count )
		begin
			update sfctaskmain
			set eventpoint       = b.eventpoint
			,eventdesc        = b.eventdesc
			,createdate       = b.createdate
			,createby         = b.createby
			,collectcount     = b.collectcount
			,disabled         = b.disabled
			,note             = b.note
			,formname         = b.formname
			,field1           = b.field1
			,field2           = b.field2
			,passcode         = b.passcode
			,failcode         = b.failcode
			,nopassfailaction = b.nopassfailaction
			,lasteditby       = b.lasteditby
			,lasteditdt       = b.lasteditdt
			,beforewhid       = b.beforewhid
			,afterwhid        = b.afterwhid
			,eventtype        = b.eventtype
			from sfctaskmain a(nolock), @table_sfctaskmain b where a.eventpoint =b.eventpoint and b.rowid = @count

		end
		else
		begin
			INSERT INTO sfctaskmain WITH (ROWLOCK) 
			SELECT eventpoint,eventdesc,createdate,createby,collectcount,disabled,note,formname,field1,field2,passcode,failcode,nopassfailaction,lasteditby,lasteditdt,beforewhid,afterwhid,eventtype FROM @table_sfctaskmain where rowid  = @count
		end
		set @count = @count + 1

	end
	
end 

COMMIT TRANSACTION

IF @m_nShowUpdateResult = 1
	SELECT * FROM sfctaskmain (NOLOCK) WHERE eventpoint IN (SELECT eventpoint FROM @table_sfctaskmain)
ELSE
	SELECT * FROM @table_sfctaskmain
