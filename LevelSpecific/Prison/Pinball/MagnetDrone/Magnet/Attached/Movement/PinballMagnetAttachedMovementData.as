class UPinballMagnetAttachedMovementData : USweepingMovementData
{
	access Protected = protected, UPinballMagnetAttachedMovementResolver (inherited);
	access ProtectedForMovement = protected, UBaseMovementResolver (inherited), UHazeMovementComponent (inherited);

	default DefaultResolverType = UPinballMagnetAttachedMovementResolver;

	access:Protected
	bool bIsProxy = false;

	access:ProtectedForMovement
	bool PrepareProxyMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp, float DeltaTime)
	{
		if(!PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bIsProxy = true;
		IterationTime = DeltaTime;

		return true;
	}

	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		bIsProxy = false;

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		auto Other = Cast<UPinballMagnetAttachedMovementData>(OtherBase);
		bIsProxy = Other.bIsProxy;
	}
#endif
}