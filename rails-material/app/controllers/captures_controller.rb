class CapturesController < ApplicationController
  before_action :set_capture, only: [:show, :edit, :update, :destroy]

  # GET /captures
  # GET /captures.json
  def index
    if params[:id] and params[:mime]
      @captures = Capture.where("participant_id = ? and mime_type = ?", params[:id], params[:mime]).reverse
    elsif params[:id] 
      @captures = Participant.find(params[:id]).captures.reverse
    else
      @captures = Capture.all
    end
    # render :json => params
  end

  # GET /captures/1
  # GET /captures/1.json
  def show
  end

  # GET /captures/new
  def new
    @capture = Capture.new
  end

  # GET /captures/1/edit
  def edit
  end

  # POST /captures
  # POST /captures.json
  def create
    @capture = Capture.new(capture_params)
    @capture.participant = Participant.find(@capture.participant_id)
    respond_to do |format|
      if @capture.save

        file = "public" + @capture.file_url
        ext = File.extname(file)
        puts ext
        if ext == ".webm"
          dir = File.dirname(file)
          name = File.basename(file, ".*")
          movie = FFMPEG::Movie.new(file)
          options = {resolution: "320x240"}
          transcoder_options = {preserve_aspect_ratio: :width}
          movie.transcode(dir + "/" + name + ".mp4", options, transcoder_options)
          mp4 = File.new(dir + "/" + name + ".mp4")
          @capture.file = mp4
          @capture.save
        end
        format.html { redirect_to @capture, notice: 'Capture was successfully created.' }
        format.json { render :show, status: :created, location: @capture }
      else
        format.html { render :new }
        format.json { render json: @capture.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /captures/1
  # PATCH/PUT /captures/1.json
  def update
    respond_to do |format|
      if @capture.update(capture_params)
        format.html { redirect_to @capture, notice: 'Capture was successfully updated.' }
        format.json { render :show, status: :ok, location: @capture }
      else
        format.html { render :edit }
        format.json { render json: @capture.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /captures/1
  # DELETE /captures/1.json
  def destroy
    @capture.destroy
    respond_to do |format|
      format.html { redirect_to captures_url, notice: 'Capture was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_capture
      @capture = Capture.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def capture_params
      params.require(:capture).permit(:file, :file_cache, :tags, :mime_type, :participant_id)
    end
end
