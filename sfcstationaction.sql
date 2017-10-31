PRINT '-----------------------------------------------------------------------------'
PRINT ' Insert station action for Label Enhancement									'
PRINT ' For eFoxSFC Juarez	bPC	0311     											'
PRINT '-----------------------------------------------------------------------------'
PRINT ''


DECLARE @m_strDefaultPlantID	VARCHAR(20),
	@m_strPlantID		VARCHAR(20),
	@m_strUserName		VARCHAR(30),
	@m_strActionParam	VARCHAR(100),
	@m_intSeqNo			INT,

	@m_bAbort		BIT,
	@m_bDeleteOldData	BIT,
	@m_InsertData		BIT,
	@m_bShowUpdateResult	BIT,

	@m_bSettingRoHSControl	BIT


----- PLEASE MAKE SURE THE SETTING IS RIGHT -----
SET @m_strUserName	= 'SYSTEM'
SET @m_intSeqNo	= 0
SET @m_bDeleteOldData	= 0
SET @m_InsertData	= 1
SET @m_bShowUpdateResult= 1

SET @m_bSettingRoHSControl = 0
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
--CPC
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp  PRODUCTION Phase II')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('JZ bPC BenchMark DB')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp TEST PHASE II') 

--select * from econtrolvalue(nolock)where controlname = 'DATABASE_TYPE'
IF NOT EXISTS (SELECT 1 FROM econtrolvalue a (NOLOCK), @table_DatabaseType b WHERE a.controlname = 'DATABASE_TYPE' and a.controlvalue=b.controlvalue)
BEGIN
	PRINT 'This script has not been configured to run against this DB... ABORTING!'
	RETURN
END



DECLARE @table_sfcaction TABLE
(
	[actionname] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[actiondesc] [varchar] (50) NULL ,
	[isactioncode] [bit] NULL ,
	[lasteditby] [varchar] (20) NULL ,
	[lasteditdt] [datetime] NULL ,
	[rowid] INT IDENTITY
)

DECLARE @table_sfcstationaction TABLE
(
	[macaddress] [varchar] (50) NOT NULL ,
	[routeid] [varchar] (20) NOT NULL ,
	[eventpoint] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[actionname] [varchar] (50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL ,
	[actionparam] [varchar] (128) NOT NULL ,
	[enabled] [bit] NOT NULL ,
	[denyaction] [bit] NULL ,
	[actioncount] [smallint] NOT NULL ,
	[seqno] [int] NOT NULL ,
	[lasteditby] [varchar] (20) NULL ,
	[lasteditdt] [datetime] NULL,
	[rowid] INT IDENTITY
)
-------------------Action--------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------sfcstationaction------------------------------
----------- Station Name:  SFCA_FUN_SFC_START_WO -----------
SET @m_intSeqNo = 0
SET @m_intSeqNo = @m_intSeqNo + 10
INSERT @table_sfcstationaction(macaddress,routeid,eventpoint,actionname,actionparam,enabled,denyaction,actioncount,seqno,lasteditby,lasteditdt)
        VALUES ('ALL','','BOXLABEL','PRINT-CONTENT-3PERCENT-LABEL','PRINT-3PERCENT-LABEL,4,PRINT-CONTENT-LABEL,6',1,0,1,@m_intSeqNo,@m_strUserName,GETDATE())

INSERT @table_sfcstationaction(macaddress,routeid,eventpoint,actionname,actionparam,enabled,denyaction,actioncount,seqno,lasteditby,lasteditdt)
        VALUES ('ALL','','BOXLABEL','SFC-ALERT-DAT-P4-LABEL-POSTPASS','GRIDLOG',1,0,0,@m_intSeqNo,@m_strUserName,GETDATE())

INSERT @table_sfcstationaction(macaddress,routeid,eventpoint,actionname,actionparam,enabled,denyaction,actioncount,seqno,lasteditby,lasteditdt)
        VALUES ('ALL','','BOXLABEL','SFC-ASSIGN-BIN-ID','CTO',1,0,1,@m_intSeqNo,@m_strUserName,GETDATE())
-------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION sfcstation_data
IF @m_InsertData = 1
BEGIN
	declare @count int,
		@totcount int
	set @count =1
	set @totcount = 0 

	select top 1 @totcount = rowid from @table_sfcstationaction order by rowid desc
	while @count <= @totcount
	begin
		if exists ( select 0 FROM sfcstationaction as a, @table_sfcstationaction as b
		WHERE a.macaddress = b.macaddress AND a.eventpoint = b.eventpoint AND a.actionname = b.actionname and b.rowid = @count  )
		begin
			update sfcstationaction
			set macaddress   = b.macaddress         
				,routeid      = b.routeid            
				,eventpoint   = b.eventpoint         
				,actionname   = b.actionname         
				,actionparam  = b.actionparam        
				,enabled      = b.enabled            
				,denyaction   = b.denyaction         
				,actioncount  = b.actioncount        
				,seqno        = b.seqno              
				,lasteditby   = b.lasteditby         
				,lasteditdt   = b.lasteditdt
		         FROM sfcstationaction as a, @table_sfcstationaction as b
			WHERE a.macaddress = b.macaddress AND a.eventpoint = b.eventpoint AND a.actionname = b.actionname and b.rowid = @count  
		end
		else
		begin		
			INSERT INTO sfcstationaction WITH (ROWLOCK)
			SELECT macaddress,routeid,eventpoint,actionname,actionparam,enabled,denyaction,actioncount,seqno,lasteditby,lasteditdt
			FROM @table_sfcstationaction where rowid = @count	
		end
		set @count = @count + 1
	end
	
	set @count =1
	set @totcount = 0 
	select top 1 @totcount = rowid from @table_sfcaction order by rowid desc
	while @count <= @totcount
	begin
		if exists ( select 0 FROM sfcaction as a, @table_sfcaction as b
		WHERE a.actionname = b.actionname and b.rowid = @count  )
		begin
			update sfcaction
				set actionname	= b.actionname	
				,actiondesc	= b.actiondesc	
				,isactioncode	= b.isactioncode	
				,lasteditby	= b.lasteditby	
				,lasteditdt	= b.lasteditdt	
			FROM sfcaction as a, @table_sfcaction as b
			WHERE a.actionname = b.actionname and b.rowid = @count 
		end
		else
		begin		
			INSERT INTO sfcaction WITH (ROWLOCK)
			SELECT actionname,actiondesc,isactioncode,lasteditby,lasteditdt	
			FROM @table_sfcaction where rowid = @count	
		end
		set @count = @count + 1
	end 

END

COMMIT TRANSACTION

IF @m_bShowUpdateResult = 1
BEGIN
	SELECT a.* FROM sfcaction a (NOLOCK), @table_sfcaction b
	WHERE a.actionname = b.actionname

	SELECT a.* FROM sfcstationaction a (NOLOCK), @table_sfcstationaction b
	WHERE a.macaddress = 'ALL' AND a.eventpoint = b.eventpoint  AND a.actionname = b.actionname
END
ELSE
IF @m_bShowUpdateResult = 2
BEGIN
	SELECT * FROM @table_sfcaction
	SELECT * FROM @table_sfcstationaction
END

