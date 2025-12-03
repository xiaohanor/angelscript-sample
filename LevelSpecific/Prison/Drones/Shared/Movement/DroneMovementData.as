class UDroneMovementData : USweepingMovementData
{
	access Protected = protected, UDroneMovementResolver (inherited);

	default DefaultResolverType = UDroneMovementResolver;

	access:Protected
	bool bIsSwarmDrone = false;
	
	access:Protected
	bool bCanBounce = false;

	access:Protected
	float BounceMinimumVerticalSpeed;

	access:Protected
	float BounceRestitution;

	access:Protected
	float BounceAngleThreshold;

	access:Protected
	FRuntimeFloatCurve BounceFromHorizontalFactorOverSpeedSpline;

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;

		// For some godforsaken reason, we decided to share this movement between the two drones...
		const auto Player = Cast<AHazePlayerCharacter>(MovementComponent.Owner);
		if(Player.IsMio())
			PrepareMoveSwarmDrone(MovementComponent, CustomWorldUp);
		else
			PrepareMoveMagnetDrone(MovementComponent, CustomWorldUp);

		return true;
	}

	bool PrepareMoveSwarmDrone(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp)
	{
		bIsSwarmDrone = true;

		const auto SwarmDroneBounceComp = USwarmDroneBounceComponent::Get(MovementComponent.Owner);
		if(SwarmDroneBounceComp != nullptr)
		{
			if(SwarmDroneBounceComp.bIsInBounceState)
			{
				bCanBounce = false;
			}
			else
			{
				bCanBounce = SwarmDroneBounceComp.CanBounce();
			}

			if(bCanBounce)
			{
				BounceMinimumVerticalSpeed = SwarmDroneBounceComp.Settings.BounceMinimumVerticalSpeed;
				BounceRestitution = SwarmDroneBounceComp.Settings.BounceRestitution;
				BounceAngleThreshold = SwarmDroneBounceComp.Settings.BounceAngleThreshold;
				BounceFromHorizontalFactorOverSpeedSpline = SwarmDroneBounceComp.Settings.BounceFromHorizontalFactorOverSpeedSpline;
			}
		}
		else
		{
			bCanBounce = false;
		}

		return true;
	}

	bool PrepareMoveMagnetDrone(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp)
	{
		bIsSwarmDrone = false;

		const auto MagnetDroneBounceComp = UMagnetDroneBounceComponent::Get(MovementComponent.Owner);

		if(MagnetDroneBounceComp != nullptr)
		{
			if(MagnetDroneBounceComp.bIsInBounceState)
			{
				bCanBounce = false;
			}
			else
			{
				bCanBounce = true;
			}

			if(bCanBounce)
			{
				BounceMinimumVerticalSpeed = MagnetDroneBounceComp.Settings.BounceMinimumVerticalSpeed;
				BounceRestitution = MagnetDroneBounceComp.Settings.BounceRestitution;
				BounceAngleThreshold = MagnetDroneBounceComp.Settings.BounceAngleThreshold;
				BounceFromHorizontalFactorOverSpeedSpline = MagnetDroneBounceComp.Settings.BounceFromHorizontalFactorOverSpeedSpline;
			}
		}
		else
		{
			bCanBounce = false;
		}

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);

		const auto Other = Cast<UDroneMovementData>(OtherBase);
		bIsSwarmDrone = Other.bIsSwarmDrone;
		bCanBounce = Other.bCanBounce;
		BounceMinimumVerticalSpeed = Other.BounceMinimumVerticalSpeed;
		BounceRestitution = Other.BounceRestitution;
		BounceAngleThreshold = Other.BounceAngleThreshold;
		BounceFromHorizontalFactorOverSpeedSpline = Other.BounceFromHorizontalFactorOverSpeedSpline;
	}
#endif
};