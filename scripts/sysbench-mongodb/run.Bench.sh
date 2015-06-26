#!/bin/sh
set -u
set -x
set -e

ulimit -c unlimited
ulimit -n 1000000


SERVER="10.11.12.220"
RT=3600
DATADIR="/mnt/mysql/mongo"
MONGODIR="/mnt/logs/vadim/manga/rocks/mongodb-linux-x86_64-3.0.4-pre/bin"

# restore from backup

function StartMongo {

echo "Starting mongod..."

$MONGODIR/mongod --dbpath=$DATADIR --storageEngine=wiredTiger --logpath=$1/server.log &

set +e

while true;
do
$MONGODIR/mongo --eval "db.stats()" 

if [ "$?" -eq 0 ]
then
  break
fi

sleep 30

echo -n "."
done

set -e

}


# Determine run number for selecting an output directory
RUN_NUMBER=-1

if [ -f ".run_number" ]; then
  read RUN_NUMBER < .run_number
fi

if [ $RUN_NUMBER -eq -1 ]; then
        RUN_NUMBER=0
fi

OUTDIR=res$RUN_NUMBER
mkdir -p $OUTDIR

StartMongo $OUTDIR

RUN_NUMBER=`expr $RUN_NUMBER + 1`
echo $RUN_NUMBER > .run_number

runid="par640"

iostat -dmx 10 >> $OUTDIR/iostat.$runid.res &
dstat -t -v --nocolor 10 > $OUTDIR/dstat_plain.$runid.res  &

cp $0 $OUTDIR

#./innodb_stat.sh $RT $SERVER $PORT >> $OUTDIR/innodb.${runid}.$i.res &
#./tpcc_start -h $SERVER -P $PORT -d tpcc$WH -u root -p "" -w $WH -c $par -r 10 -l $RT | tee -a $OUTDIR/tpcc.${runid}.$i.out 
echo "Running..."
bash run.simple.bash config.bash $OUTDIR | tee -a $OUTDIR/script.out.txt

