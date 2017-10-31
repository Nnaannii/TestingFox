PRINT '--------------------------------------------------------------------------------------'
PRINT ' Insert configure data of cvschedule for Download Schedule Date WO SAP to SFC     '
Print '--------------------------------------------------------------------------------------'

 DECLARE @m_strUserName            VARCHAR(20),
         @m_bAbort                 BIT,
         @m_bDeleteOldData         BIT,
         @m_InsertData             BIT,
         @m_nShowUpdateResult      BIT,
         @m_intSeqNo               BIT,
         @m_strPlantID             VARCHAR(20)

----- PLEASE MAKE SURE THE SETTING IS RIGHT -----
SET @m_strUserName       = 'SYSTEM'
SET @m_intSeqNo          = 0
SET @m_bDeleteOldData    = 0
SET @m_InsertData        = 1
SET @m_nShowUpdateResult = 1
-------------------------------------------------
----- DONN'T MODIFY -----
SET @m_bAbort = 0
-------------------------
SELECT @m_strPlantID = controlvalue FROM econtrolvalue (NOLOCK) WHERE controlname = 'DEFAULT FACTORY ID'
SET @m_strPlantID = ISNULL(@m_strPlantID, '')
IF @m_strPlantID = ''
BEGIN
    Print 'The DEFAULT FACTORY ID of current DB is empty!'
    SET @m_bAbort = 1
End

IF LEN(@m_strUserName) = 0
BEGIN
Print   'Please setting a valid User Name!'
SET @m_bAbort = 1
End
IF @m_bAbort = 1
Return
DECLARE @table_DatabaseType TABLE
(
   [CONTROLVALUE] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)

--Configure the DBs that this script file can be run against.
-- BPC
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp  PRODUCTION Phase II')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('JZ BPC eFox BenchMark DB')
INSERT INTO @table_DatabaseType ([CONTROLVALUE]) VALUES ('eCMMS Hp TEST PHASE II')

--SELECT * FROM econtrolvalue(NOLOCK)WHERE controlname = 'DATABASE_TYPE' 
IF NOT EXISTS (SELECT 1 FROM econtrolvalue a (NOLOCK), @table_DatabaseType b WHERE a.controlname = 'DATABASE_TYPE' and a.controlvalue=b.controlvalue)
BEGIN
    Print 'This script has not been configured to run against this DB... ABORTING!'
    Return
End
DECLARE @table_cvschedule TABLE
(
	[schedulename] [varchar] (50)  COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[description] [varchar] (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[scheduletype] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[disabled] [bit] NOT NULL,
	[inhold] [bit] NOT NULL,
	[seperateable] [bit] NOT NULL,
	[runsystem] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[runmodule] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[runfunction] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[runtype] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[runvalue] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[schedulepara1] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[schedulepara2] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[schedulepara3] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[schedulepara4] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[schedulepara5] [varchar] (100)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[lasttakeby] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[lasttakedate] [char] (10)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[lasttaketime] [char] (8)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[lasttakestatus] [varchar] (30)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[rerunallow] [int] NULL,
	[reruncount] [int] NULL,
	[logfile] [varchar] (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[logfilebak] [varchar] (255)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[logfiledays] [int] NULL,
	[schedulesecond] [int] NULL,
	[nexttime] [datetime] NULL,
	[lasteditby] [varchar] (20)  COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[lasteditdt] [datetime] NULL,
	[rowid] INT IDENTITY 
)
------------------------------------------------------------------------------------------
SET @m_intSeqNo = 0
SET @m_intSeqNo = @m_intSeqNo + 10
INSERT @table_cvschedule(schedulename,description,scheduletype,disabled,inhold,seperateable,runsystem,runmodule,runfunction,runtype,runvalue,schedulepara1,schedulepara2,schedulepara3,schedulepara4,schedulepara5,lasttakeby,lasttakedate,lasttaketime,lasttakestatus,rerunallow,reruncount,logfile,logfilebak,logfiledays,schedulesecond,nexttime,lasteditby,lasteditdt)
 VALUES ('SFCA_FUN_SAP_IMP_SCHEDULE_DATE','Download Schedule Date from SAP to SFC','SAPDOWNLOAD_SCHEDULE_DATE_WO',0,0,0,'','','','','','','','','','',@m_strUserName,left(convert(varchar,getdate(),120),10),right(convert(varchar,getdate(),120),8),'',1,0,'','',10,0,'',@m_strUserName,getdate())

------------------------------------------------------------------------------------------

print right(convert(varchar,getdate(),120),8)

BEGIN TRANSACTION cvschedule_data
/*
IF @m_bDeleteOldData = 1
BEGIN
   DELETE FROM cvschedule WITH (ROWLOCK) WHERE schedulename IN (SELECT schedulename FROM @table_cvschedule)
End
*/

IF @m_InsertData = 1
	declare @count int,
		@totcount int
	set @count =1
	set @totcount = 0 

	select top 1 @totcount = rowid from @table_cvschedule order by rowid desc
	while @count <= @totcount
	begin
		if exists (select 0 from cvschedule a(nolock), @table_cvschedule b where a.schedulename = b.schedulename and rowid =@count )
		begin
			update cvschedule
			SET schedulename    = b.schedulename          
				,description     = b.description           
				,scheduletype    = b.scheduletype          
				,disabled        = b.disabled              
				,inhold          = b.inhold                
				,seperateable    = b.seperateable          
				,runsystem       = b.runsystem             
				,runmodule       = b.runmodule             
				,runfunction     = b.runfunction           
				,runtype         = b.runtype               
				,runvalue        = b.runvalue              
				,schedulepara1   = b.schedulepara1         
				,schedulepara2   = b.schedulepara2         
				,schedulepara3   = b.schedulepara3         
				,schedulepara4   = b.schedulepara4         
				,schedulepara5   = b.schedulepara5         
				,lasttakeby      = b.lasttakeby            
				,lasttakedate    = b.lasttakedate          
				,lasttaketime    = b.lasttaketime          
				,lasttakestatus  = b.lasttakestatus        
				,rerunallow      = b.rerunallow            
				,reruncount      = b.reruncount            
				,logfile         = b.logfile               
				,logfilebak      = b.logfilebak            
				,logfiledays     = b.logfiledays           
				,schedulesecond  = b.schedulesecond        
				,nexttime        = b.nexttime              
				,lasteditby      = b.lasteditby            
				,lasteditdt      = b.lasteditdt   
			from cvschedule a(nolock), @table_cvschedule b where a.schedulename = b.schedulename and rowid =@count
		end
		else
		begin
    			INSERT INTO cvschedule WITH (ROWLOCK) 
			SELECT schedulename,description,scheduletype,disabled,inhold,seperateable,runsystem,runmodule,runfunction,
			runtype,runvalue,schedulepara1,schedulepara2,schedulepara3,schedulepara4,schedulepara5,lasttakeby,lasttakedate,lasttaketime,lasttakestatus,
			rerunallow,reruncount,logfile,logfilebak,logfiledays,schedulesecond,nexttime,lasteditby,lasteditdt FROM @table_cvschedule
		end
		set @count = @count +1
	end

COMMIT TRANSACTION

IF @m_nShowUpdateResult = 1
   SELECT * FROM cvschedule (NOLOCK) WHERE schedulename IN (SELECT schedulename FROM @table_cvschedule)
Else
   SELECT * FROM @table_cvschedule