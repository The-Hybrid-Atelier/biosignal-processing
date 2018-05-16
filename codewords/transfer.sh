TARG="../rails-material/public/data"
mkdir -p $TARG

rsync -av --exclude="data/pilot/*" --exclude="*.mp4" --exclude="*.xlsx" --exclude="*.MOV" --exclude="*.log" --exclude="*.DS_Store" --exclude="*.txt" --exclude="*.csv" data $TARG


