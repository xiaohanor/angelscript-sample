class USummitSiegeBeamCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	USiegeActivationComponent ActivationComp;
	USiegeMagicBeamComponent BeamComp;
	USiegeHealthComponent HealthComp;

	float NextFireTime;
	float FireDuration = 4.0;
	float FireTime;

	FHazeAcceleratedVector AccelVector;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ActivationComp = USiegeActivationComponent::Get(Owner);
		BeamComp = USiegeMagicBeamComponent::Get(Owner);
		HealthComp = USiegeHealthComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HealthComp.bAlive)
			return false;

		if (!CanFire())
			return false;
		
		if (!ActivationComp.bCanBeActive)
			return false;

		if (Time::GameTimeSeconds < NextFireTime)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (FireDuration <= 0.0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		AccelVector.SnapTo(BeamComp.ForwardVector);
		FireTime = FireDuration;

		FVector EndLoc = BeamComp.ForwardVector * BeamComp.BeamRange;
		FVector RelativeStart = BeamComp.RelativeLocation;
		FVector RelativeEnd = BeamComp.WorldTransform.InverseTransformPosition(EndLoc);

		FSiegeMagicBeamParams Params;
		// Params.Start = RelativeStart;
		// Params.End = RelativeEnd;
		Params.Start = BeamComp.WorldLocation;
		Params.End = EndLoc;

		Params.Width = BeamComp.BeamWidth;
		Params.AttachedLocation = BeamComp;
		USiegeMagicBeamEffectHandler::Trigger_StartBeam(Owner, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		NextFireTime = Time::GameTimeSeconds + BeamComp.WaitTime;
		USiegeMagicBeamEffectHandler::Trigger_StopBeam(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DesiredDirection = (GetClosestPlayer().ActorLocation - BeamComp.WorldLocation).GetSafeNormal();
		AccelVector.AccelerateTo(DesiredDirection, 3.5, DeltaTime);
		FVector EndLoc = BeamComp.WorldLocation + AccelVector.Value.GetSafeNormal() * BeamComp.BeamRange;

		FVector RelativeStart = BeamComp.RelativeLocation;
		FVector RelativeEnd = BeamComp.WorldTransform.InverseTransformPosition(EndLoc);

		FSiegeMagicBeamParams Params;
		// Params.Start = RelativeStart;
		// Params.End = RelativeEnd;
		Params.Start = BeamComp.WorldLocation;
		Params.End = EndLoc;
		USiegeMagicBeamEffectHandler::Trigger_UpdateBeamLocations(Owner, Params);
		// Debug::DrawDebugLine(BeamComp.WorldLocation, EndLoc, FLinearColor::Red, 50.0);
		FireTime -= DeltaTime;
	}

	AHazePlayerCharacter GetClosestPlayer() const
	{
		return Game::Mio.GetDistanceTo(Owner) < Game::Zoe.GetDistanceTo(Owner) ? Game::Mio : Game::Zoe;
	}

	bool CanFire() const
	{
		if (GetClosestPlayer().GetDistanceTo(Owner) < BeamComp.MinRangeRequired)
		{
			float Distance = GetClosestPlayer().OtherPlayer.GetDistanceTo(Owner);
			if (Distance < BeamComp.MinRangeRequired)
				return false;
			else 
				return true;
		}

		return true;
	}

};