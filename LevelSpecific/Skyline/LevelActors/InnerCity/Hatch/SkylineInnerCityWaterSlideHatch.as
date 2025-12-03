event void FHatchOpened();
class ASkylineInnerCityWaterSlideHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	UPROPERTY(DefaultComponent, Attach = Pivot)
	USceneComponent OpeningRotPivot;

	UPROPERTY(DefaultComponent, Attach = OpeningRotPivot)
	UStaticMeshComponent HatchMesh;

	UPROPERTY(DefaultComponent, Attach = OpeningRotPivot)
	UStaticMeshComponent MioHatchLocation;

	UPROPERTY(DefaultComponent, Attach = OpeningRotPivot)
	UStaticMeshComponent ZoeHatchLocation;

	UPROPERTY(EditAnywhere)
	ADoubleInteractionActor DoubleInteract;
	
	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike KaChunkAnimation;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FallOffAnimation;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BubblesVFX;

	UPROPERTY(EditInstanceOnly)
	ASkylineInnerCitySwimCurrent SwimCurrent;

	UPROPERTY()
	FHatchOpened OnHatchOpened;
	
	FVector LoosenStartLoc;
	FQuat LoosenStartRot;

	FVector Outwards;
	FVector Downwards;

	FVector OGLocation;
	FQuat OGRotation;

	bool bButtonMashing = false;
	bool bStickSpinning = false;
	bool bOpenComplete = false;

	bool bTriggeredPipe = false;

	private FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = false;
	private FStickSpinSettings SpinSettings;
	private FHazeAcceleratedFloat AccOpen;
	const float MaxSpinRightyTighy = 0.33;
	const float MinSpinLeftyLoosey = -25.0; // if we want a longer stick spin, set this to like -100 for example

	const float WrongWayMaxDegrees = -5.0; // small number to show we're getting stuck
	const float TotalSpinDegrees = 360.0;

	float WrongWayEventCooldown = 0.0;

	float AccumulatedStickSpinValue = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwimCurrent.SetActorTickEnabled(false);
		FallOffAnimation.BindUpdate(this, n"AnimationUpdate");
		FallOffAnimation.BindFinished(this, n"HandleFallOffAnimationCompleted");
		KaChunkAnimation.BindUpdate(this, n"HandleKaChunkAnimationUpdate");
		KaChunkAnimation.BindFinished(this, n"HandleKaChunkAnimationCompleted");
		DoubleInteract.OnDoubleInteractionCompleted.AddUFunction(this, n"HandleInteractCompleted");
		OGLocation = ActorLocation;
		OGRotation = ActorQuat;
		Outwards = ActorForwardVector;
		Downwards = -ActorUpVector;
	}

	UFUNCTION()
	private void HandleInteractCompleted()
	{
		DoubleInteract.DisableDoubleInteraction(this);
		StartPushHatch();
	}
	
	UFUNCTION()
	private void StartPushHatch()
	{
		PlayerStartStickSpin();
		// PlayerStartButtonMash();

		bOpenComplete = false;
		UPlayerMovementComponent::Get(Game::Mio).FollowComponentMovement(MioHatchLocation, this);
		UPlayerMovementComponent::Get(Game::Zoe).FollowComponentMovement(ZoeHatchLocation, this);
		for (auto Player : Game::Players)
		{
			auto PushHatchComp = USkylineInnerCityPlayerPushHatchComponent::GetOrCreate(Player);
			PushHatchComp.bActive = true;
			PushHatchComp.Hatch = this;
		}
		USkylineInnerCityWaterSlideHatchEventHandler::Trigger_OnStartTurning(this);
	}

	UFUNCTION()
	private void StopPushHatch()
	{
		OnHatchOpened.Broadcast();

		bStickSpinning = false;
		bButtonMashing = false;
		bOpenComplete = true;
		UPlayerMovementComponent::Get(Game::Mio).UnFollowComponentMovement(this);
		UPlayerMovementComponent::Get(Game::Zoe).UnFollowComponentMovement(this);
		for (auto Player : Game::Players)
		{
			auto PushHatchComp = USkylineInnerCityPlayerPushHatchComponent::GetOrCreate(Player);
			
			PushHatchComp.bActive = false;
		}

		DoTheKaChunkRumble();
		PlayersDoTheBackwardsSomersault();
		USkylineInnerCityWaterSlideHatchEventHandler::Trigger_OnStopTurning(this);	
		HandleMaterialChange();	
	}

	// ----------------------

	private void PlayerStartButtonMash()
	{
		bButtonMashing = true;
		for (auto Player : Game::Players)
		{
			UButtonMashComponent ButtonMashComp = UButtonMashComponent::Get(Player);
			Player.StartButtonMash(MashSettings, this);
			ButtonMashComp.SetAllowButtonMashCompletion(this, false);
		}
	}

	private void PlayerStartStickSpin()
	{
		bStickSpinning = true;
		for (auto Player : Game::Players)
		{
			SpinSettings.bAllowPlayerCancel = false;
			SpinSettings.bAllowSpinClockwise = true;
			SpinSettings.bAllowSpinCounterClockwise = true;
			SpinSettings.bBlockOtherGameplay = false; // Do this manually to not cancel swimming
			// SpinSettings.MaximumSpinPosition = MaxSpinRightyTighy;
			// SpinSettings.bUseMaximumSpinPosition = true;
			SpinSettings.bForceCounterClockwiseUI = true;
			Player.StartStickSpin(SpinSettings, this);
		}
	}

	UFUNCTION(DevFunction)
	private void PlayersDoTheBackwardsSomersault()
	{
		// push mio & zoe off
		auto MioComp = USkylineInnerPlayerBackwardsSomersaultComponent::Get(Game::Mio);
		if (MioComp != nullptr)
		{
			auto MioMove = UPlayerMovementComponent::Get(Game::Mio);
			FSkylineInnerPlayerBackwardsSomersaultData Data;
			Data.StartGravityDirection = -ActorForwardVector;
			Data.TargetGravityDirection = MioMove.GetGravityDirection();
			MioComp.AddSomersault(Data);
			// ApplyPoi(Game::Mio);
		}
		auto ZoeComp = USkylineInnerPlayerBackwardsSomersaultComponent::Get(Game::Zoe);
		if (ZoeComp != nullptr)
		{
			auto ZoeMove = UPlayerMovementComponent::Get(Game::Zoe);
			FSkylineInnerPlayerBackwardsSomersaultData Data;
			Data.StartGravityDirection = -ActorForwardVector;
			Data.TargetGravityDirection = ZoeMove.GetGravityDirection();
			ZoeComp.AddSomersault(Data);
			// ApplyPoi(Game::Zoe);
		}
	}

	void ApplyPoi(AHazePlayerCharacter Player)
	{
		FHazePointOfInterestFocusTargetInfo Poi;
		Poi.SetFocusToMeshComponent(HatchMesh);
		Poi.WorldOffset = FVector(0, 0, 0.0);
		FApplyPointOfInterestSettings Settings;
		Settings.Duration = 3.0;
		Player.ApplyPointOfInterest(this, Poi, Settings);
	}

	UFUNCTION(DevFunction)
	private void StickBack()
	{
		SetActorLocation(OGLocation);
		SetActorRotation(OGRotation);
		FallOffAnimation.Stop();
		KaChunkAnimation.Stop();
	}

	UFUNCTION(DevFunction)
	private void ReplayLoosen()
	{
		SetActorLocation(OGLocation);
		SetActorRotation(OGRotation);
		FallOffAnimation.Stop();
		DoTheKaChunkRumble();
	}

	private void DoTheKaChunkRumble()
	{
		KaChunkAnimation.PlayFromStart();
		if (BubblesVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BubblesVFX, ActorLocation);
	}

	UFUNCTION()
	private void HandleKaChunkAnimationUpdate(float CurrentValue)
	{
		float MagicValue = 0.2;
		Game::Mio.SetFrameForceFeedback(MagicValue, MagicValue, MagicValue, MagicValue, CurrentValue);
		Game::Zoe.SetFrameForceFeedback(MagicValue, MagicValue, MagicValue, MagicValue, CurrentValue);

		Pivot.SetRelativeLocation(FVector(5.0 * KaChunkAnimation.Position, 0.0, 0.0));
		Pivot.SetRelativeRotation(FRotator(0.0, 0.0, 3.0 * CurrentValue));
	}

	UFUNCTION()
	private void HandleKaChunkAnimationCompleted()
	{
		StartLoosenAnimation();
		USkylineInnerCityWaterSlideHatchEventHandler::Trigger_OnHatchComeOff(this);
		if (BubblesVFX != nullptr)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(BubblesVFX, ActorLocation);
	}

	private void StartLoosenAnimation()
	{
		LoosenStartLoc = ActorLocation;
		LoosenStartRot = ActorQuat;
		FallOffAnimation.PlayFromStart();
		bTriggeredPipe = false;
		HatchMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void AnimationUpdate(float CurrentValue)
	{
		FVector Out = Math::EaseOut(FVector::ZeroVector, Outwards * 400.0, FallOffAnimation.Position, 3.0);
		FVector DestinationLoc = LoosenStartLoc + (Downwards * 500.0);
		SetActorLocation(Math::Lerp(LoosenStartLoc, DestinationLoc, CurrentValue) + Out);
		SetActorRotation(FQuat::Slerp(LoosenStartRot, Downwards.ToOrientationQuat(), CurrentValue));
		// Debug::DrawDebugString(ActorLocation, ""  + FallOffAnimation.Position);
		if (!bTriggeredPipe && FallOffAnimation.Position > 0.7)
		{
			bTriggeredPipe = true;
			SwimCurrent.SetActorTickEnabled(true);
		}
	}

	UFUNCTION()
	private void HandleFallOffAnimationCompleted()
	{
	}

	// --------

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bButtonMashing)
			UpdateButtonMashOpening(DeltaSeconds);
		if (bStickSpinning)
			UpdateStickSpinOpening(DeltaSeconds);
	}

	void UpdateStickSpinOpening(float DeltaSeconds)
	{
		if (!bOpenComplete)
		{
			float PushMultiplier = 1.0;
			float PushVelocity = 0.0;
			for (auto Player : Game::Players)
			{
				auto SpinState = Player.GetStickSpinState(this);
				// Debug::DrawDebugString(Player.ActorLocation, "" + SpinState.SpinVelocity);
				PushMultiplier *= Math::Abs(SpinState.SpinVelocity) > KINDA_SMALL_NUMBER ? 1.0 : 0.0; 
				PushVelocity += SpinState.SpinVelocity;
				if (SpinState.SpinVelocity > KINDA_SMALL_NUMBER && SpinState.Direction == EStickSpinDirection::SpinClockwise)
				{
					WrongWayEventCooldown -= DeltaSeconds;
					if (WrongWayEventCooldown < 0.0)
					{
						WrongWayEventCooldown = 1.0;
						FSkylineInnerCityWaterSlideHatchStuckWrongWayEventParams Params;
						Params.TurningWrongPlayer = Player;
						USkylineInnerCityWaterSlideHatchEventHandler::Trigger_OnHatchStuckWrongWay(this, Params);
					}
					Player.SetFrameForceFeedback(0.1, 0.1, 0.1, 0.1, 0.3);
				}
			}

			AccumulatedStickSpinValue += PushVelocity * PushMultiplier * DeltaSeconds;
			AccumulatedStickSpinValue = Math::Clamp(AccumulatedStickSpinValue, MinSpinLeftyLoosey, MaxSpinRightyTighy);
			// Debug::DrawDebugString(ActorLocation, "" + AccumulatedStickSpinValue);

			if (AccumulatedStickSpinValue <= MinSpinLeftyLoosey + KINDA_SMALL_NUMBER)
			{
				bOpenComplete = true;
				for (auto Player : Game::Players)
					Player.StopStickSpin(this);
			}
		}

		if (bOpenComplete)
		{
			AccOpen.SpringTo(-1.0, 250.0, 0.3, DeltaSeconds);
			if (AccOpen.Velocity < KINDA_SMALL_NUMBER)
			{
				StopPushHatch();
			}
		}
		else
		{
			float StickSpinAlpha = AccumulatedStickSpinValue > 0.0 ? AccumulatedStickSpinValue / Math::Abs(MaxSpinRightyTighy) : AccumulatedStickSpinValue / Math::Abs(MinSpinLeftyLoosey);
			float StickSpinDuration = AccumulatedStickSpinValue > 0.0 ? 5.0 : 1.5;
			AccOpen.AccelerateTo(StickSpinAlpha * 0.7, StickSpinDuration, DeltaSeconds);
		}

		float BouncingOpenness = Math::Abs(AccOpen.Value);
		if (AccOpen.Value > 0.0)
			OpeningRotPivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, WrongWayMaxDegrees, BouncingOpenness)));
		else
			OpeningRotPivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, TotalSpinDegrees, BouncingOpenness)));
	}

	void UpdateButtonMashOpening(float DeltaSeconds)
	{
		float LeastButtonMashing = MAX_flt;
		if (!bOpenComplete)
		{
			for (auto Player : Game::Players)
			{
				float PlayerMash = Player.GetButtonMashProgress(this);
				if (PlayerMash < LeastButtonMashing)
					LeastButtonMashing = PlayerMash;
			}

			if (LeastButtonMashing >= 1.0 - KINDA_SMALL_NUMBER)
			{
				bOpenComplete = true;
				for (auto Player : Game::Players)
					Player.StopButtonMash(this);
			}
		}

		if (bOpenComplete)
		{
			AccOpen.SpringTo(1.0, 250.0, 0.3, DeltaSeconds);
			if (AccOpen.Velocity < KINDA_SMALL_NUMBER)
			{
				StopPushHatch();
			}
		}
		else
			AccOpen.AccelerateTo(LeastButtonMashing * 0.5, 1.0, DeltaSeconds);

		float BouncingOpenness = Math::Abs(AccOpen.Value);
		OpeningRotPivot.SetRelativeRotation(FRotator(0.0, 0.0, Math::Lerp(0.0, -400.0, BouncingOpenness)));
	}

	UFUNCTION(BlueprintEvent)
	void HandleMaterialChange(){}
	
};