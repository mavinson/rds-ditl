#!/bin/bash

# Setup variables
WORKDIR=/tmp
WORKFILE=w`date +%Y%m%d%H%M%s`.txt
VALIDFILE=dbs`date +%Y%m%d%H%M%s`.txt

if [ "$#" -ne 4 ]; then
   echo "ERROR:   Invalid number of parameters. Pass the parameter group name, command, region and oracle edition"
   echo "EXAMPLE: '$0 [parameter-group] [start,stop,list] [us-east-1,us-east-2] [oracle-ee,oracle-ee-cdb,oracle-se2,oracle-se2-cdb]'"
   echo "EXAMPLE: '$0 default.oracle-ee-12.2 stop us-east-2 oracle-ee'"
   echo ""
else 

   PARAMETER_GROUP=$1
   COMMAND=$2
   REGION=$3
   EDITION=$4

   if [[ "$REGION" != "us-east-1" ]] && [[ "$REGION" != "us-east-2" ]] ; then
         echo "ERROR:   Invalid region [$REGION]. Pass the correct region (us-east-1, us-east-2)"
         echo ""
         exit
   fi

   if [[ "$EDITION" != "oracle-ee" ]] && [[ "$EDITION" != "oracle-ee-cdb" ]] && [[ "$EDITION" != "oracle-se2" ]] && [[ "$EDITION" != "oracle-se2-cdb" ]] ; then
         echo "ERROR:   Invalid edition [$EDITION]. Pass the correct edition (oracle-ee,oracle-ee-cdb,oracle-se2,oracle-se2-cdb)"
         echo ""
         exit
   fi

   if [ $COMMAND == "start" ]; then
         COMMAND=start-db-instance

   elif [ $COMMAND == "stop" ]; then
         COMMAND=stop-db-instance

   elif [ $COMMAND == "list" ]; then
         echo "Searching for RDS for Oracle $EDITION instances in region $REGION using Parameter Group $PARAMETER_GROUP"

   else 
         echo "ERROR:   Invalid command [$COMMAND]. Pass the correct command (start, stop, list)"
         echo ""
         exit
   fi

   PROCESSFILE=$WORKDIR/$WORKFILE
   VALIDDBS=$WORKDIR/$VALIDFILE

   aws rds describe-db-instances --region $REGION --filters Name=engine,Values=$EDITION --query 'DBInstances[*].[DBInstanceIdentifier]' --output text > $PROCESSFILE

   while read DBNAME;
         do

            PG=`aws rds describe-db-instances --region $REGION --db-instance-identifier $DBNAME --query 'DBInstances[*].[DBParameterGroups]' --output text | cut -f1`

            if [ $PG == $PARAMETER_GROUP ]; then

               if [ $COMMAND == "list" ]; then
                  echo "$DBNAME"

               else 
                  aws rds $COMMAND --region $REGION --db-instance-identifier $DBNAME > /dev/null &
               fi
            fi

         done < $PROCESSFILE

   rm -f $PROCESSFILE
   rm -f $VALIDDBS

fi
