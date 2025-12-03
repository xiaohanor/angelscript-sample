class UIslandFloatingMinePatrolCapability : UHazeChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	AIslandFloatingMine Mine;

	UHazeMovementComponent MoveComp;
	USimpleMovementData Movement;

	const float MinDistThreshold = 70.0;

	float SpeedTowardsTarget = 0.0;
	int CurrentPatrolLocationIndex = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mine = Cast<AIslandFloatingMine>(Owner);

		MoveComp = UHazeMovementComponent::Get(Mine);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(Mine.PatrolLocations.IsEmpty())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FVector TargetLocation = Mine.PatrolLocations[CurrentPatrolLocationIndex].ActorLocation;
		FVector DirToTarget = (TargetLocation - Mine.BobRoot.WorldLocation).GetSafeNormal();
		SpeedTowardsTarget = Mine.ActorVelocity.DotProduct(DirToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(IsCloseEnoughToLocation())
					GetNextTarget();
				
				FVector TargetLocation = Mine.PatrolLocations[CurrentPatrolLocationIndex].ActorLocation;
				FVector DirToTarget = (TargetLocation - Mine.ActorLocation).GetSafeNormal();

				FQuat QuatFacingPlayer = FQuat::MakeFromX(DirToTarget);
				Movement.InterpRotationTo(QuatFacingPlayer, Mine.PatrolRotationSpeed);

				SpeedTowardsTarget = Math::FInterpTo(SpeedTowardsTarget, Mine.PatrolMaxSpeed, DeltaTime, Mine.PatrolAcceleration);
				FVector Velocity = DirToTarget * SpeedTowardsTarget;
				Movement.AddVelocity(Velocity);


			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}
			MoveComp.ApplyMove(Movement);
		}
	}

	bool IsCloseEnoughToLocation() const
	{
		FVector TargetLocation = Mine.PatrolLocations[CurrentPatrolLocationIndex].ActorLocation;
		float DistSqrd = TargetLocation.DistSquared(Mine.ActorLocation);

		return DistSqrd <= Math::Square(MinDistThreshold);
	}

	void GetNextTarget()
	{
		CurrentPatrolLocationIndex++;
		if(CurrentPatrolLocationIndex >= Mine.PatrolLocations.Num())
		{
			if(Mine.bPingPongPatrol)
			{
				TArray<AActor> NewArray;
				for(int i = Mine.PatrolLocations.Num() - 1; i >= 0; i--)
				{
					NewArray.Add(Mine.PatrolLocations[i]);
				}
				Mine.PatrolLocations = NewArray;
			}
			CurrentPatrolLocationIndex = 0;
		}
	}
}