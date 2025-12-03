class UHoverPerchMovementComponent : UHazeMovementComponent
{
	private FVector Internal_PreviousLocation;

	void ApplyMove(UBaseMovementData DataType) override
	{
		Internal_PreviousLocation = Owner.ActorLocation;
		Super::ApplyMove(DataType);
	}

	FVector GetPreviousLocation() const property
	{
		return Internal_PreviousLocation;
	}

	FVector GetCurrentLocation() const property
	{
		return Owner.ActorLocation;
	}
}