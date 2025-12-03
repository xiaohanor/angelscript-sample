class UPinballProxyTeleportingMovementData : UTeleportingMovementData
{
	default DefaultResolverType = UPinballProxyTeleportingMovementResolver;
	bool bIsProxy = false;

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
};