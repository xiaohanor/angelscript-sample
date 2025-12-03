struct FCentipedeSegmentConstraint
{
	UCentipedeSegmentComponent Start = nullptr;
	UCentipedeSegmentComponent End = nullptr;
}

struct FCentipedeBodyPlayerWorldUpOverride
{
	// TInstigated<FVector> WorldUpOverride;  // :'c doesn't work...

	private const FVector DefaultWorldUp = FVector::UpVector;
	private FVector WorldUpOverride = DefaultWorldUp;

	void ApplyWorldUpOverride(FVector WorldUp)
	{
		WorldUpOverride = WorldUp;
	}

	void ClearWorldUpOverride()
	{
		WorldUpOverride = DefaultWorldUp;
	}

	FVector GetWorldUp() const
	{
		return WorldUpOverride;
	}
}