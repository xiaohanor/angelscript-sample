class UIslandJetpackComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UIslandJetpackSettings JetpackSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCapabilitySheet JetpackSheet;

	AHazePlayerCharacter Player;
	AIslandJetpack Jetpack;

	private bool bIsOn = false;
	private float Charge = 1.0;
	bool bThrusterIsOn = false;
	bool bIsRecharging = false;

	/** Turns false when boost is over
		Turns true when landing */ 
	bool bHasInitialBoost = true;
	bool bActivatedExternally = false;
	bool bBoosting = false;
	bool bDashing = false;
	bool bQueuedPhaseWallBoost = false;
	TOptional<uint> FrameOfEnterPhaseWall;
	FVector2D AnimLastPhaseWallDirection;

	TArray<FInstigator> HoldEffectInstigators;

	float TimeOfDash;
	float TimeWhenRespawned = -1;
	float TimeWhenUsedPhasableWall = -1;

	UIslandJetpackPhasableComponent PhasableComponent;
	UHazeCrumbSyncedFloatComponent ChargeSyncComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ApplyDefaultSettings(JetpackSettings);

		Player.OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		UPlayerRespawnComponent::Get(Player).OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawn");
		PhasableComponent = UIslandJetpackPhasableComponent::GetOrCreate(Player);

		ChargeSyncComponent = UHazeCrumbSyncedFloatComponent::GetOrCreate(Player, n"JetpackeChargeSync");
		ChargeSyncComponent.Value = 1.0;
	}

	UFUNCTION()
	private void OnPlayerRespawn(AHazePlayerCharacter RespawnedPlayer)
	{
		TimeWhenRespawned = Time::GameTimeSeconds;
	}
	
	UFUNCTION(BlueprintCallable)
	void ToggleJetpack(bool bToggleOn)
	{
		if(bToggleOn)
		{
			// Don't allow to turn on jetpack if it is already turned on
			if(bIsOn)
				return;

			bIsOn = true;
			Player.StartCapabilitySheet(JetpackSheet, this);
		}
		else
		{
			if(!bIsOn)
				return;

			bIsOn = false;
			Player.StopCapabilitySheet(JetpackSheet, this);
		}
	}

	bool InPhasableWallSpline()
	{
		return PhasableComponent.PhasablePlatformSpline != nullptr || PhasableComponent.bQueuedPhasableSlowdown;
	}

	bool IsOn() const
	{
		return bIsOn;
	}

	bool HasFullCharge() const
	{
		return Charge == 1.0;
	}

	bool HasEmptyCharge() const
	{
		return Charge == 0.0;
	}

	void ChangeChargeLevel(float Change, bool bIsBoosting)
	{
		if (Time::GetGameTimeSince(TimeWhenRespawned) >= JetpackSettings.RespawnChargeDepletionDelay)
			SetChargeLevel(Charge + Change, bIsBoosting);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!HasControl())
			UpdateChargeValue(ChargeSyncComponent.Value);
	}

	void SetChargeLevel(float NewCharge, bool bIsBoosting)
	{
		bBoosting = bIsBoosting;
		if (HasControl())
		{
			UpdateChargeValue(NewCharge);
			ChargeSyncComponent.Value = Charge;
		}
	}

	private void UpdateChargeValue(float NewCharge)
	{
		if(bBoosting)
			Jetpack.FuelMeterMaterial.SetVectorParameterValue(n"MeterColor", JetpackSettings.BoostingColor);
		else
			Jetpack.FuelMeterMaterial.SetVectorParameterValue(n"MeterColor", JetpackSettings.ChargedColor);

		if(NewCharge < Charge
		&& bIsRecharging)
			return;

		if(Charge >= 0.0 && NewCharge <= 0.0)
			UIslandJetpackEventHandler::Trigger_FuelEmpty(Jetpack);

		Charge = NewCharge;
		Charge = Math::Clamp(Charge, 0.0, 1.0);

		const float AlphaIncrements = 17.0;
		float AmountOfSlitsLitUp = Math::CeilToFloat(Charge * AlphaIncrements);
		Jetpack.FuelMeterMaterial.SetScalarParameterValue(n"FuelAlpha", AmountOfSlitsLitUp / AlphaIncrements);
		
	}

	void FillCharge()
	{
		SetChargeLevel(1.0, false);
	}

	float GetChargeLevel() const
	{
		if (!HasControl())
			return ChargeSyncComponent.Value;
		return Charge;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		if(!IsOn())
			return;
		
		AIslandPhasablePlatform PhasablePlatform = Cast<AIslandPhasablePlatform>(OtherActor);
		if(PhasablePlatform == nullptr)
			return;

		//bool bIsVerticalPhaseWall = Math::Abs(PhasablePlatform.ActorForwardVector.DotProduct(FVector::UpVector)) > 0.9;
		
		FVector BoostDir;
		if(PhasablePlatform.bBoostWall)
		{
			if (!PhasablePlatform.CanPhaseThrough(Player))
				return;
			
			bQueuedPhaseWallBoost = true;
			// BoostDir = FVector::UpVector;
			// FVector Boost = BoostDir * JetpackSettings.PhasablePlatformBoostImpulseSize;
			// Player.AddMovementImpulse(Boost);
		}
		else
		{
			if (!PhasablePlatform.CanPhaseThrough(Player))
				return;

			PhasableComponent.PhasablePlatformSpline = PhasablePlatform.PlatformSpline;
			FVector VelocityDir = Player.ActorVelocity.GetSafeNormal();
			float VelocityDotPlatformForward = VelocityDir.DotProduct(PhasablePlatform.ActorForwardVector);
			BoostDir = VelocityDotPlatformForward > 0.0 ? PhasablePlatform.ActorForwardVector : -PhasablePlatform.ActorForwardVector;
			if (PhasablePlatform.bAlwaysLaunchForward)
				BoostDir = PhasablePlatform.ActorForwardVector;

			FVector RedirectedVelocity = Player.ActorVelocity.ProjectOnToNormal(BoostDir);
			Player.SetActorVelocity(RedirectedVelocity);
			
			FVector Boost = BoostDir * JetpackSettings.PhasablePlatformBoostImpulseSize;
			Player.AddMovementImpulse(Boost);

			FVector ToPlatform = (PhasablePlatform.Cone.WorldLocation - Player.ActorCenterLocation).VectorPlaneProject(PhasablePlatform.ActorForwardVector);
			if (VelocityDotPlatformForward >= 0.0 && PhasablePlatform.bAlwaysLaunchForward)
				Player.AddMovementImpulse(ToPlatform);

			if (PhasablePlatform.PlatformSpline == nullptr)
				FrameOfEnterPhaseWall.Set(Time::FrameNumber);
		}

		FVector Dir = BoostDir;

		AnimLastPhaseWallDirection = FVector2D(Player.ActorRightVector.DotProduct(Dir), Player.ActorForwardVector.DotProduct(Dir));

		UIslandJetpackEventHandler::Trigger_HitPhasableWall(Jetpack);
		FillCharge();

		auto PhaseSpline = Cast<AIslandPhasablePlatformSpline>(PhasablePlatform.AttachParentActor);
		if(PhaseSpline == nullptr)
		{
			Player.SetAnimTrigger(n"Refill");
		}

		TimeWhenUsedPhasableWall = Time::GameTimeSeconds;

		if (!bThrusterIsOn)
			bActivatedExternally = true;

		// Queue a slowdown if last gate on spline, otherwise remove queued slowdown as we want to make sure the movement to activates again
		// if (PhasablePlatform.bIsLastSplinePhasable)
		// 	PhasableComponent.bQueuedPhasableSlowdown = true;
		// else
		// 	PhasableComponent.bQueuedPhasableSlowdown = false;
	}

	bool EnteredPhaseWallThisFrame()
	{
		if(!FrameOfEnterPhaseWall.IsSet())
			return false;

		return FrameOfEnterPhaseWall.Value == Time::FrameNumber;
	}

	void AddHoldEffectInstigator(FInstigator Instigator)
	{
		HoldEffectInstigators.AddUnique(Instigator);
		if(HoldEffectInstigators.Num() == 1)
			Jetpack.HoldJetEffect.Activate(false);
	}

	void RemoveHoldEffectInstigator(FInstigator Instigator)
	{
		HoldEffectInstigators.RemoveSingleSwap(Instigator);
		if(HoldEffectInstigators.Num() == 0)
			Jetpack.HoldJetEffect.Deactivate();
	}
};