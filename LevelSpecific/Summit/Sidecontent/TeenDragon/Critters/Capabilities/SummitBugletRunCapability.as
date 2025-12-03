class USummitBugletRunCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitBuglet Buglet;
	FVector RunDirection;
	FVector StartingLoc;
	float RunSpeed = 2000.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Buglet = Cast<ASummitBuglet>(Owner);
		StartingLoc = Buglet.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Buglet.State != ESummitBugletState::Run)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (BugletReachedMaxDistance())
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
		Buglet.ActivateVanish();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(Buglet.ActorLocation);
		RunDirection = (Buglet.ActorLocation - ClosestPlayer.ActorLocation).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		RunDirection.Normalize();

		Buglet.ActorLocation += RunDirection * RunSpeed * DeltaTime;
		
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

		Buglet.ActorRotation = RunDirection.Rotation();
	}

	bool BugletReachedMaxDistance() const
	{
		return (Buglet.ActorLocation - StartingLoc).Size() > Buglet.RunRadius ? true : false;
	}
};