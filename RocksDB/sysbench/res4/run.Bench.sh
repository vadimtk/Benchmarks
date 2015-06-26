#!/bin/sh
set -u
set -x
set -e

ulimit -c unlimited


SERVER="10.11.12.220"
RT=3600

# restore from backup

function stratmysqld {


for i in `seq 1 $NINST`
do
PORT=$((3305+$i))
ssh $SERVER "$MYSQLDIR/bin/mysqld --defaults-file=$CONFIG --datadir=$DR$i --innodb_thread_concurrency=0 --innodb-buffer-pool-size=${bp}G --innodb-log-file-size=$logsz --innodb_flush_log_at_trx_commit=$trxv --log-error=$DR$i/mysql.error.log --socket=/tmp/mysql$PORT --port=$PORT --innodb_data_home_dir=$IDR$i --innodb_log_group_home_dir=$LR$i --basedir=$MYSQLDIR &"

set +e

while true;
do
mysql -Bse "SELECT 1" mysql -h $SERVER -P $PORT

if [ "$?" -eq 0 ]
then
  break
fi

sleep 30

echo -n "."
done
set -e

done

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

RUN_NUMBER=`expr $RUN_NUMBER + 1`
echo $RUN_NUMBER > .run_number

runid="par640"


iostat -dmx 10 >> $OUTDIR/iostat.$runid.res &
dstat -t -v --nocolor 10 > $OUTDIR/dstat_plain.$runid.res  &

cp $0 $OUTDIR

#./innodb_stat.sh $RT $SERVER $PORT >> $OUTDIR/innodb.${runid}.$i.res &
#./tpcc_start -h $SERVER -P $PORT -d tpcc$WH -u root -p "" -w $WH -c $par -r 10 -l $RT | tee -a $OUTDIR/tpcc.${runid}.$i.out 
echo "Running..."
bash run.simple.bash | tee -a $OUTDIR/script.out.txt

