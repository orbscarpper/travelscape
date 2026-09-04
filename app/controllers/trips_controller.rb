class TripsController < ApplicationController
  before_action :authenticate_user!

  def index
    @trips = current_user.trips
  end

  def show
    @trip = current_user.trips.find(params[:id])
  end

  def new
    @trip = current_user.trips.new
  end

  def create
    @trip = current_user.trips.new(trip_params)

    if @trip.save
      redirect_to @trip, notice: "Trip created successfully!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @trip = current_user.trips.find(params[:id])
  end

  def update
    @trip = current_user.trips.find(params[:id])

    if @trip.update(trip_params)
      redirect_to @trip, notice: "Trip updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip = current_user.trips.find(params[:id])
    @trip.destroy

    redirect_to trips_path, notice: "Trip deleted successfully!"
  end

  private

  def trip_params
    params.require(:trip).permit(
      :title,
      :destination,
      :description,
      :start_date,
      :end_date,
      :budget,
      :travel_style,
      :traveling_with
    )
  end
end
