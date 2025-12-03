class USummitTailCatapultBasketReleaseCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	ASummitTailCatapultBasket Basket;

	float StartPullBackAlpha;
	FRotator StartRotation;
	FRotator TargetRotation;

	bool bHasLaunched = false;

	UPlayerMovementComponent MioMovementComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Basket = Cast<ASummitTailCatapultBasket>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Basket.bTailIsAttached)
			return false;

		if(!Basket.bIsReleasing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(ActiveDuration > Basket.ReleaseDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartPullBackAlpha = Basket.PulledBackAlpha;

		StartRotation = Basket.CatapultRotateRoot.WorldRotation;

		float TargetPitch = Math::Lerp(Basket.ActorRotation.Pitch, Basket.ReleasedRotation.Pitch, StartPullBackAlpha);
		FRotator NewTargetRotation = Basket.ActorRotation;
		NewTargetRotation.Pitch = TargetPitch; 
		TargetRotation = NewTargetRotation;

		FSummitTailCatapultBasketOnReleaseParams Params;
		Params.PulledBackPercent = StartPullBackAlpha;
		USummitTailCatapultBasketEventHandler::Trigger_OnRelease(Basket, Params);

		for(auto Player : Game::Players)
		{
			Player.PlayWorldCameraShake(Basket.LaunchCameraShake, this, Basket.ClimbMeshComp.WorldLocation, Basket.LaunchShakeInnerRadius, Basket.LaunchShakeOuterRadius);

			float DistToPlayer = Basket.ClimbMeshComp.WorldLocation.Distance(Player.ActorLocation);
			float DistAlpha = Math::GetPercentageBetweenClamped(Basket.LaunchShakeOuterRadius, Basket.LaunchShakeInnerRadius, DistToPlayer);
			Player.PlayForceFeedback(Basket.LaunchRumble, false, false, this, DistAlpha);
		}

		bHasLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Basket.bIsReleasing = false;

		if(Basket.bMioIsInBasket
		&& !bHasLaunched)
			LaunchMio();

		Basket.CatapultRotateRoot.WorldRotation = TargetRotation;
		Basket.AccRotation.SnapTo(TargetRotation);
		float GoBackDelay = Basket.MaxGoBackDelay * StartPullBackAlpha;
		Basket.GoBackTimeStamp = Time::GameTimeSeconds + GoBackDelay;

		USummitTailCatapultBasketEventHandler::Trigger_OnResetEnd(Basket);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / Basket.ReleaseDuration;
		FRotator NewRotation = Math::LerpShortestPath(StartRotation, TargetRotation, Alpha);
		// Basket.AccRotation.AccelerateTo(TargetRotation, Basket.ReleaseDuration, DeltaTime);
		Basket.AccRotation.SnapTo(NewRotation);
		// Basket.CatapultRotateRoot.SetWorldRotation(Basket.AccRotation.Value);
		Basket.CatapultRotateRoot.SetWorldRotation(NewRotation);

		if(Alpha > 0.5
		&& Basket.bMioIsInBasket
		&& !bHasLaunched)
			LaunchMio();
	}

	private void LaunchMio()
	{
		FVector LaunchImpulse = 
			(Basket.ActorUpVector * Basket.ReleaseMaxImpulseUpwards * StartPullBackAlpha)
			+ (-Basket.ActorForwardVector * Basket.ReleaseMaxImpulseForward * StartPullBackAlpha);

		if(MioMovementComp == nullptr)
			MioMovementComp = UPlayerMovementComponent::Get(Game::Mio);
		MioMovementComp.AddPendingImpulse(LaunchImpulse);
		Game::Mio.FlagForLaunchAnimations(LaunchImpulse);

		if(StartPullBackAlpha > 0.6)
		{
			MioMovementComp.AddMovementIgnoresActor(this, Basket);
			Timer::SetTimer(this, n"RemoveMovementIgnore", 0.5);
		}

		
		bHasLaunched = true;
	}

	UFUNCTION()
	private void RemoveMovementIgnore()
	{
		MioMovementComp.RemoveMovementIgnoresActor(this);
	}
};