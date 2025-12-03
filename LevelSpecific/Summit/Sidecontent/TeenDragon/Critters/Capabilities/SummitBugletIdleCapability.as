class USummitBugletIdleCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitBuglet Buglet;

	FVector TargetPatrolLoc;
	FVector StartingLoc;
	FRotator MoveRotation;

	float MinRate = 1.5;
	float MaxRate = 3.0;
	float CurrentTime;
	float MinDistance = 200.0;
	float MaxDistance = 400.0;

	float MoveSpeed = 150.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Buglet = Cast<ASummitBuglet>(Owner);
		StartingLoc = Buglet.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Buglet.State != ESummitBugletState::Idle)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Buglet.State != ESummitBugletState::Idle)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Time::GameTimeSeconds > CurrentTime)
		{
			CurrentTime = Time::GameTimeSeconds + Math::RandRange(MinRate, MaxRate);
			TargetPatrolLoc = GetNewPatrolLocation();
		}

		Buglet.ActorLocation = Math::VInterpConstantTo(Buglet.ActorLocation, TargetPatrolLoc, DeltaTime, MoveSpeed);

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseLine();
		TraceSettings.IgnoreActor(Buglet);
		
		FVector Start = Buglet.ActorLocation + FVector::UpVector * 50.0;
		FVector End = Buglet.ActorLocation + -FVector::UpVector * 500.0;
		FHitResult Hit = TraceSettings.QueryTraceSingle(Start, End);

		if (Hit.bBlockingHit)
		{
			Buglet.ActorLocation = Hit.ImpactPoint;
		}

		Buglet.ActorRotation = (TargetPatrolLoc - Buglet.ActorLocation).Rotation();

		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(Buglet.ActorLocation);

		if (ClosestPlayer.GetDistanceTo(Buglet) < Buglet.RadiusCheck)
		{
			Buglet.State = ESummitBugletState::Run;
		}
	}

	FVector GetNewPatrolLocation()
	{
		FVector RDirection = FVector(Math::RandRange(-0.9, 0.9), Math::RandRange(-0.9, 0.9), 0.0);
		RDirection.Normalize();
		return StartingLoc + (RDirection * Math::RandRange(MinDistance, MaxDistance));
	}
};