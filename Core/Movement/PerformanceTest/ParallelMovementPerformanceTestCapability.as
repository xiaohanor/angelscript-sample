#if TEST
const FConsoleVariable CVar_ParallelMovementPerformanceTest_ResolverType("Haze.Movement.Parallel.PerformanceTest_ResolverType", DefaultValue = 0);

class UParallelMovementPerformanceTestCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	USimpleMovementData SimpleMovement;
	USteppingMovementData SteppingMovement;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		SimpleMovement = MoveComp.SetupSimpleMovementData();
		SteppingMovement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;
			
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UBaseMovementData Movement;
		EParallelTestMovementPerformanceTestResolverType ResolverType = EParallelTestMovementPerformanceTestResolverType(CVar_ParallelMovementPerformanceTest_ResolverType.GetInt());

		if(ResolverType >= EParallelTestMovementPerformanceTestResolverType::MAX || ResolverType < EParallelTestMovementPerformanceTestResolverType(0))
			return;

		switch(ResolverType)
		{
			case EParallelTestMovementPerformanceTestResolverType::Simple:
				Movement = SimpleMovement;
				if(!ensure(MoveComp.PrepareMove(SimpleMovement)))
					return;
				break;

			case EParallelTestMovementPerformanceTestResolverType::Stepping:
				Movement = SteppingMovement;
				if(!ensure(MoveComp.PrepareMove(SteppingMovement)))
					return;
				break;
		}

		if (HasControl())
		{
			FVector Location = StartLocation + FQuat(FVector::UpVector, ActiveDuration * 2).ForwardVector * 200;
			Movement.AddDelta(Location - Owner.ActorLocation);
		}
		else
		{
			Movement.ApplyCrumbSyncedGroundMovement();
		}

		MoveComp.ApplyMoveParallel(Movement);
	}
};
#endif