class UArcTraversalComponent : UTraversalComponentBase
{
	private bool bIsTraversing = false;
	private FTraversalArc TraversingArc;

	private FVector ReachedDestination = FVector(BIG_NUMBER);

	private float WantedSpeed = 2500.0;

	// Movement capability sets this when destination is reached, consume by behaviour
	bool IsAtDestination(FVector Destination)
	{
		if (Destination.IsWithinDist(ReachedDestination, 10.0))
			return true;
		return false;
	}

	void Traverse(FTraversalArc Arc, float TargetSpeed)
	{
		bIsTraversing = true;
		TraversingArc = Arc;
		WantedSpeed = TargetSpeed;
		ReachedDestination = FVector(BIG_NUMBER);
	}

	bool HasDestination() const
	{
		return bIsTraversing;
	}

	void ConsumeDestination(FTraversalArc& OutArc)
	{
		bIsTraversing = false;
		OutArc = TraversingArc;
	}

	float GetSpeed() property
	{
		return WantedSpeed;
	}

	void ReachDestination(FVector Destination)
	{
		ReachedDestination = Destination;
	}

	protected void Reset() override
	{
		Super::Reset();
		ReachedDestination = FVector(BIG_NUMBER);
	}
}
