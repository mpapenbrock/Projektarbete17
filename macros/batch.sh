#!/usr/bin/env bash

nJobs=200
nEventsPerJob=1000

JOBFILE="job.sh"
OUTPUTDIR="../../data_new/"

iJob=101
while [ $iJob -le $nJobs ]; do
  JOBFILE="job$iJob.sh"
  
  echo "#!/usr/bin/env bash" > $JOBFILE
  echo "OUTPUTDIR=$OUTPUTDIR" >> $JOBFILE
  echo "nEvents=$nEventsPerJob" >> $JOBFILE
  echo "iJob=$iJob" >> $JOBFILE
  
  #echo 'root -q -b sim.C"($nEvents,$iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b digi.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b recoideal.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  
  #echo 'root -q -b generateMomData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b generateTSMomData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b generatePatData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  echo 'root -q -b generatePatPiData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b generateTSPatData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  #echo 'root -q -b generateClassData.C"($iJob,\"$OUTPUTDIR\")"' >> $JOBFILE
  
  chmod 755 $JOBFILE
  ./$JOBFILE
  #rm $JOBFILE
  let iJob+=1
done

#rm core_dump_*
#rm job*
