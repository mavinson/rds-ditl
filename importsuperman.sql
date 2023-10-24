SET VERIFY OFF
SET FEEDBACK OFF
SET SERVEROUTPUT ON SIZE 30000
-- 
DECLARE
  h1 NUMBER;                 -- Data Pump job handle
  status VARCHAR2(20);       -- Status of job
  table_list varchar2(3000); -- Dynamic table list
  le ku$_LogEntry;           -- For WIP and error messages
  js ku$_JobStatus;          -- The job status from get_status
  jd ku$_JobDesc;            -- The job description from get_status
  sts ku$_Status;            -- The status object returned by get_status
BEGIN
--
-- Get the valid tables to import. The tables to be imported are in the superman.importtables table.
--
   SELECT listagg(''''||table_name||'''', ',') WITHIN GROUP (ORDER BY table_name)
      INTO table_list
      FROM superman.importtables;
--
-- Create a Data Pump job to do an import
--
   h1 := DBMS_DATAPUMP.OPEN(operation => 'IMPORT',
                           job_mode =>'SCHEMA',
                           job_name => NULL);
--
-- If multiple files are required, use the wildcard expression of '%U'.
-- 
   DBMS_DATAPUMP.ADD_FILE(handle => h1,
                         filename => 'demoexp%U.dmp',
                         directory => 'EFS_DATA_PUMP_DIR',
                         filetype => dbms_datapump.ku$_file_type_dump_file);
-- 
   DBMS_DATAPUMP.ADD_FILE(handle => h1,
                         filename => 'demoimp.log',
                         directory => 'EFS_DATA_PUMP_DIR',
                         filetype => dbms_datapump.ku$_file_type_log_file);
-- 
-- Determine which objects to exclude ('EXCLUDE_PATH_EXPR') or include ('INCLUDE_PATH_EXPR')
-- Gather object list via "select distinct object_type from dba_objects order by object_type;"
--
   DBMS_DATAPUMP.METADATA_FILTER(h1,'EXCLUDE_PATH_EXPR','IN (''FUNCTION'', ''PROCEDURE'', ''DATABASE LINK'', ''VIEW'' ,''JOB'', ''SEQUENCE'', ''PACKAGE'')');
--
--
-- If the table already exists in the destination schema, skip it (leave
-- the preexisting table alone). This is the default, but it does not hurt
-- to specify it explicitly. You can also replace or append rows. We will append rows.
--
   DBMS_DATAPUMP.SET_PARAMETER(h1,'TABLE_EXISTS_ACTION','APPEND');
--
-- A metadata filter is used to specify the schemas that will be imported.
--
   DBMS_DATAPUMP.METADATA_FILTER(h1,'SCHEMA_LIST','''SOE'',''BATMAN'',''ROBIN''');
--
-- A metadata filter is used to specify the tables that will be imported. This will use the 
-- table that we defined in the previous steps.
--
   DBMS_DATAPUMP.METADATA_FILTER(h1, 'NAME_LIST', table_list, 'TABLE');
--
-- A metadata remap will map a table from the SOURCE TABLE to the TARGET TABLE.
--
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_TABLE','JOBCODE','JOBCODE_TBL');
--
-- A metadata remap will map all schema objects from a SOURCESCHEMA to a TARGETSCHEMA.
--
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_SCHEMA','SOE','SUPERMAN');
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_SCHEMA','BATMAN','SUPERMAN');
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_SCHEMA','ROBIN','SUPERMAN');
--
-- A metadata remap will map tablespaces from a SOURCE TABLESPACE to a TARGET TABLESPACE.
--
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_TABLESPACE','USERS','SUPERMAN_DATA');
   DBMS_DATAPUMP.METADATA_REMAP(h1,'REMAP_TABLESPACE','SOE','SUPERMAN_DATA');
--
-- A new OID will be assigned for each imported table.
-- This eliminates the "ORA-02304: invalid object identifier literal" error message
--
   DBMS_DATAPUMP.METADATA_TRANSFORM(h1,'OID',0,null) ;
--
-- Start the job. An exception is returned if something is not set up properly.
--
   DBMS_DATAPUMP.START_JOB(h1);
   DBMS_DATAPUMP.WAIT_FOR_JOB(h1,status);
   DBMS_DATAPUMP.DETACH(h1);
   EXCEPTION
   WHEN OTHERS THEN
     DBMS_DATAPUMP.DETACH(h1);
     RAISE;
END;
/

