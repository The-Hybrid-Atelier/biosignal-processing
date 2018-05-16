echo "Transferring files"
mkdir -p "../rails-material/public/data"
rsync -av --exclude="data/pilot/*" --exclude="*.mp4" --exclude="*.xlsx" --exclude="*.MOV" --exclude="*.log" --exclude="*.DS_Store" --exclude="*.txt" --exclude="*.csv" data "../rails-material/public"


