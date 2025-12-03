class ASanctuaryBloodGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftDoorPivotComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightDoorPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent BigRotComp;

	UPROPERTY(DefaultComponent, Attach = BigRotComp)
	USceneComponent BigLeftComp;

	UPROPERTY(DefaultComponent, Attach = BigRotComp)
	USceneComponent BigRightComp;

	UPROPERTY(DefaultComponent, Attach = BigRotComp)
	UFauxPhysicsAxisRotateComponent SmallRotComp;

	UPROPERTY(DefaultComponent, Attach = SmallRotComp)
	USceneComponent SmallLeftComp;

	UPROPERTY(DefaultComponent, Attach = SmallRotComp)
	USceneComponent SmallRightComp;

	UPROPERTY(DefaultComponent)
	ULightBirdResponseComponent LightBirdResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilities.Add(n"SanctuaryBloodGateDarkPortalTargetEnablingCapability");

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike OpenGateTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike AccelerationTimeLike;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike BloodFillTimeLike;

	UPROPERTY(Category = Settings)
	float RotationSpeed = 10.0;

	UPROPERTY(Category = Settings)
	float SlideIntoPlaceDegreeTolerance = 7.0;

	UPROPERTY(Category = Settings)
	float InnerSlideIntoPlaceDegreeTolerance = 15.0;

	UPROPERTY(Category = Settings)
	float OpposingRotationMultiplier = 0.5;

	UPROPERTY(Category = Settings)
	float DarkPortalRightSideStartGrabAngle = 20.0;

	UPROPERTY(Category = Settings)
	float DarkPortalLeftSideStartGrabAngle = 160.0;

	UPROPERTY(Category = Settings)
	float DarkPortalGrabNextAngle = 60.0;

	UPROPERTY(Category = Settings)
	float DarkPortalAllowedAngle = 120.0;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBloodGatePillar LeftPillarActor = nullptr;
	UPROPERTY(EditInstanceOnly)
	ASanctuaryBloodGatePillar RightPillarActor = nullptr;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBloodGateCentipedeLeg> CentipedeLegs;
	int CentipedeLegIndex = 0;

	float AccelerationSpeedMultiplier = 0.0;
	float BigMultiplier = 1.0;
	float SmallMultiplier = 1.0;

	float SnappedPreserve = 1.0;

	bool bInnerWasSnappedToOuter = false;
	bool bInnerIsSnappedToOuter = false;
	float InnerSnapToOuterTimer = 1.0;

	bool bOuterWasSnappedToBlood = false;
	bool bOuterIsSnappedToBlood = false;

	bool bGateOpened = false;
	bool bGateOpening = false;
	bool bShouldTriggerEvents = true;

	bool bDarkPortalActive = false;
	bool bLightBirdActive = false;

	const float StrongRotationForce = Math::DegreesToRadians(90.0);
	const float WeakRotationForce = StrongRotationForce * OpposingRotationMultiplier;
	const float NoFauxForceMultiplier = 0.46;

	const float SnapIntoPlaceDuration = 0.3;
	const float CountAsStoppedTreshold = KINDA_SMALL_NUMBER * 3.0;

	FHazeAcceleratedFloat AccBigRotForce;
	float BigStartSlideIntoPlaceRotRoll;
	float BigStartSlideIntoPladeTimestamp;

	FHazeAcceleratedFloat AccSmallRotForce;
	float SmallStartSlideIntoPlaceRotRoll;
	float SmallStartSlideIntoPladeTimestamp;

	private USanctuaryUglyProgressionPlayerComponent ProgressionComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LightBirdResponseComponent.OnAttached.AddUFunction(this, n"BirdAttached");
		LightBirdResponseComponent.OnDetached.AddUFunction(this, n"BirdDetached");
		LightBirdResponseComponent.OnIlluminated.AddUFunction(this, n"HandleIlluminated");
		LightBirdResponseComponent.OnUnilluminated.AddUFunction(this, n"HandleUnilluminated");
		AccelerationTimeLike.BindUpdate(this, n"AccelerationTimeLikeUpdate");
		BloodFillTimeLike.BindUpdate(this, n"BloodFillTimeLikeUpdate");
		BloodFillTimeLike.BindFinished(this, n"BloodFillTimeLikeFinished");
		OpenGateTimeLike.BindUpdate(this, n"OpenGateTimeLikeUpdate");

		if (LeftPillarActor != nullptr)
		{
			if (LeftPillarActor.DarkPortalResponseComponent != nullptr)
			{
				LeftPillarActor.DarkPortalResponseComponent.OnAttached.AddUFunction(this, n"DarkPortalAttached");
				LeftPillarActor.DarkPortalResponseComponent.OnDetached.AddUFunction(this, n"DarkPortalDetached");
			}
		}
		if (RightPillarActor != nullptr)
		{
			if (RightPillarActor.DarkPortalResponseComponent != nullptr)
			{
				RightPillarActor.DarkPortalResponseComponent.OnAttached.AddUFunction(this, n"DarkPortalAttached");
				RightPillarActor.DarkPortalResponseComponent.OnDetached.AddUFunction(this, n"DarkPortalDetached");
			}
		}

		DarkPortalResponseComponent.OnGrabbed.AddUFunction(this, n"HandleDarkPortalGrab");
		DarkPortalResponseComponent.OnReleased.AddUFunction(this, n"HandleDarkPortalRelease");

		DevTogglesBloodGate::DebugDraw.MakeVisible();
		DevTogglesBloodGate::FauxPhysics.MakeVisible();
		DevTogglesBloodGate::PretendBirdActive.MakeVisible();
		DevTogglesBloodGate::PretendFishActive.MakeVisible();

		ProgressionComp = USanctuaryUglyProgressionPlayerComponent::GetOrCreate(Game::Mio);

		DevTogglesBloodGate::StartOpen.MakeVisible();			
	}

	void ForceSnapOpenFromCheckpoint()
	{
		FRotator SmallRelativeRot = SmallRotComp.RelativeRotation;
		SmallRelativeRot.Roll = 0.0;
		SmallRotComp.SetRelativeRotation(SmallRelativeRot);

		FRotator BigRelativeRot = BigRotComp.RelativeRotation;
		BigRelativeRot.Roll = 0.0;
		BigRotComp.SetRelativeRotation(BigRelativeRot);

		SmallLeftComp.AttachToComponent(LeftDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		SmallRightComp.AttachToComponent(RightDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		BigLeftComp.AttachToComponent(LeftDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		BigRightComp.AttachToComponent(RightDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);

		for (int iLeg = 0; iLeg < CentipedeLegs.Num(); iLeg++)
		{
			CentipedeLegs[CentipedeLegIndex].Activate();
			CentipedeLegIndex++;
		}

		LeftDoorPivotComp.SetRelativeRotation(FRotator(0.0, -60.0, 0.0));
		RightDoorPivotComp.SetRelativeRotation(FRotator(0.0, 60.0, 0.0));
		SetActorTickEnabled(false);
		BP_OpenGate();
	}

	UFUNCTION()
	private void BirdAttached()
	{
		FSanctuaryBloodGateSinglePlayerEffectEventData Data;
		Data.Player = Game::Mio;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_LightBirdEngage(this, Data);
	}

	UFUNCTION()
	private void BirdDetached()
	{
		FSanctuaryBloodGateSinglePlayerEffectEventData Data;
		Data.Player = Game::Mio;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_LightBirdDisengage(this, Data);
	}

	UFUNCTION()
	private void DarkPortalAttached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		FSanctuaryBloodGateSinglePlayerEffectEventData Data;
		Data.Player = Game::Zoe;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_DarkPortalEngage(this, Data);
	}

	UFUNCTION()
	private void DarkPortalDetached(ADarkPortalActor Portal, USceneComponent AttachComponent)
	{
		FSanctuaryBloodGateSinglePlayerEffectEventData Data;
		Data.Player = Game::Zoe;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_DarkPortalDisengage(this, Data);
	}

	UFUNCTION()
	private void HandleDarkPortalGrab(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		if (!bDarkPortalActive && bShouldTriggerEvents)
		{
			USanctuaryBloodGateEffectEventHandler::Trigger_DarkPortalStartTurning(this, GetBothPlayerData());
		}
		bDarkPortalActive = true;
		if (!bLightBirdActive)
		{
			AccelerationTimeLike.PlayRate = 0.5;
			AccelerationTimeLike.Play();
		}
	}

	UFUNCTION()
	private void HandleDarkPortalRelease(ADarkPortalActor Portal, UDarkPortalTargetComponent TargetComponent)
	{
		bDarkPortalActive = DarkPortalResponseComponent.Grabs.Num() >= 1;
		if (bDarkPortalActive)
			return;

		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_DarkPortalStopTurning(this, GetBothPlayerData());

		if (!bLightBirdActive)
		{
			AccelerationTimeLike.PlayRate = 2.0;
			AccelerationTimeLike.Reverse();
		}
	}

	UFUNCTION()
	private void HandleIlluminated()
	{
		bLightBirdActive = true;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_LightBirdStartTurning(this, GetBothPlayerData());

		if (!bDarkPortalActive)
		{
			AccelerationTimeLike.PlayRate = 0.5;
			AccelerationTimeLike.Play();
		}
	}

	UFUNCTION()
	private void HandleUnilluminated()
	{
		bLightBirdActive = false;
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_LightBirdStopTurning(this, GetBothPlayerData());
		if (!bDarkPortalActive)
		{
			AccelerationTimeLike.PlayRate = 2.0;
			AccelerationTimeLike.Reverse();
		}
	}

	UFUNCTION()
	private void AccelerationTimeLikeUpdate(float Alpha)
	{
		AccelerationSpeedMultiplier = Math::Lerp(0.0, 1.0, Alpha);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSlidingPuzzleFinished()
	{
		LightBirdCompanion::GetLightBirdCompanion().CompanionComp.State = ELightBirdCompanionState::Follow;

		SmallLeftComp.AttachToComponent(LeftDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		SmallRightComp.AttachToComponent(RightDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		BigLeftComp.AttachToComponent(LeftDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		BigRightComp.AttachToComponent(RightDoorPivotComp, NAME_None, EAttachmentRule::KeepWorld);
		BloodFillTimeLike.Play();
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_BloodFlowStart(this, GetBothPlayerData());
		SetActorTickEnabled(false);
	}

	UFUNCTION()
	private void BloodFillTimeLikeUpdate(float Alpha)
	{
		if (1.0 / CentipedeLegs.Num() * CentipedeLegIndex < Alpha)
		{
			CentipedeLegs[CentipedeLegIndex].Activate();
			CentipedeLegIndex++;

			if (CentipedeLegIndex % 3 == 0)
				BP_LegsForceFeedback();
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_LegsForceFeedback(){}

	UFUNCTION()
	private void BloodFillTimeLikeFinished()
	{
		if (bShouldTriggerEvents)
			USanctuaryBloodGateEffectEventHandler::Trigger_GateUnlock(this, GetBothPlayerData());
		bShouldTriggerEvents = false;
		bGateOpening = true;
		OpenGateTimeLike.Play();
		BP_OpenGate();
	}

	UFUNCTION()
	private void OpenGate()
	{
		if (!bGateOpened)
		{
			bGateOpened = true;
			AccelerationTimeLike.Stop();
			// PrintToScreen("EntireSlideIntoPlaceTimeLike Played", 5.0);
		}
	}

	UFUNCTION(BlueprintEvent)
	private void BP_OpenGate()
	{
	}

	UFUNCTION()
	private void OpenGateTimeLikeUpdate(float Alpha)
	{
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
		FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, ActorLocation, 100000, 150000);

		LeftDoorPivotComp.SetRelativeRotation(Math::LerpShortestPath(FRotator::ZeroRotator, FRotator(0.0, -60.0, 0.0), Alpha));
		RightDoorPivotComp.SetRelativeRotation(Math::LerpShortestPath(FRotator::ZeroRotator, FRotator(0.0, 60.0, 0.0), Alpha));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (ProgressionComp.bPassedBloodGateCheckpoint || DevTogglesBloodGate::StartOpen.IsEnabled())
		{
			ForceSnapOpenFromCheckpoint();
			return;
		}

		if (DevTogglesBloodGate::FauxPhysics.IsEnabled())
		{
			FauxUpdateBigRotationViaAbilities(DeltaSeconds);
			FauxUpdateSmallRotation(DeltaSeconds);
		}

		else
		{
			ManualUpdateSmallRotation(DeltaSeconds);
			ManualUpdateBigRotationViaAbilities(DeltaSeconds);
		}

		PlayForceFeedback();

		const float ToleratedAngle = 0.1;
		const float ToleratedVelocity = 0.001;
		if (Math::IsNearlyEqual(SmallRotComp.RelativeRotation.Roll, 0.0, ToleratedAngle) && 
			Math::IsNearlyEqual(SmallRotComp.Velocity, 0.0, ToleratedVelocity) && 
			Math::IsNearlyEqual(BigRotComp.RelativeRotation.Roll, 0.0, ToleratedAngle) &&
			Math::IsNearlyEqual(BigRotComp.Velocity, 0.0, ToleratedVelocity) &&
			Math::IsNearlyEqual(AccSmallRotForce.Value, 0.0, CountAsStoppedTreshold) &&
			Math::IsNearlyEqual(AccBigRotForce.Value, 0.0, CountAsStoppedTreshold)
			)
		{
			if (HasControl())
				CrumbSlidingPuzzleFinished();
		}

	}

	private void FauxUpdateSmallRotation(float DeltaSeconds)
	{
		bool bBirdActive = bLightBirdActive || DevTogglesBloodGate::PretendBirdActive.IsEnabled();
		bool bFishActive = bDarkPortalActive || DevTogglesBloodGate::PretendFishActive.IsEnabled();
		bool bBothActive = bBirdActive && bFishActive;

		if (bBothActive)
		{
			bInnerIsSnappedToOuter = false;
			SmallRotComp.ApplyAngularForce(-StrongRotationForce);
		}

		bool bShouldBeSnappedToOuter = Math::IsNearlyEqual(SmallRotComp.RelativeRotation.Roll, 0.0, SlideIntoPlaceDegreeTolerance) && Math::IsNearlyEqual(SmallRotComp.Velocity, 0.0, KINDA_SMALL_NUMBER);
		if (bInnerIsSnappedToOuter || bShouldBeSnappedToOuter)
		{
			if (!bInnerWasSnappedToOuter && bShouldTriggerEvents)
				USanctuaryBloodGateEffectEventHandler::Trigger_AlignInnerWithOuterWheel(this, GetBothPlayerData());

			bInnerIsSnappedToOuter = true;
			bInnerWasSnappedToOuter = bInnerIsSnappedToOuter;
			SmallRotComp.ApplyAngularForce(SmallRotComp.RelativeRotation.Roll);
			return;
		}
		else if (!bInnerIsSnappedToOuter && bInnerWasSnappedToOuter && bShouldTriggerEvents)
		{
			USanctuaryBloodGateEffectEventHandler::Trigger_UnalignInnerWithOuterWheel(this, GetBothPlayerData());
		}
		bInnerWasSnappedToOuter = bInnerIsSnappedToOuter;
	}

	private void FauxUpdateBigRotationViaAbilities(float DeltaSeconds)
	{
		// OVERRIDE ROLL TARGET - auto align!
		bool bBirdActive = bLightBirdActive || DevTogglesBloodGate::PretendBirdActive.IsEnabled();
		bool bFishActive = bDarkPortalActive || DevTogglesBloodGate::PretendFishActive.IsEnabled();
		bool bBothActive = bBirdActive && bFishActive;
		bool bAnyActive = bBirdActive || bFishActive;
		if (bAnyActive)
		{
			float Force = StrongRotationForce;
			if (bBothActive)
				Force = WeakRotationForce;
			else if (bBirdActive) 
				Force *= -1.0;
			BigRotComp.ApplyAngularForce(Force);
		}
		else if (Math::IsNearlyEqual(BigRotComp.RelativeRotation.Roll, 0.0, SlideIntoPlaceDegreeTolerance))
		{
			float Direction = BigRotComp.RelativeRotation.Roll;
			BigRotComp.ApplyAngularForce(Direction * 0.5);
		}

		bOuterIsSnappedToBlood = Math::IsNearlyEqual(BigRotComp.RelativeRotation.Roll, 0.0, CountAsStoppedTreshold) && Math::IsNearlyEqual(BigRotComp.Velocity, 0.0, CountAsStoppedTreshold);
		if (DevTogglesBloodGate::DebugDraw.IsEnabled()) 
			Debug::DrawDebugString(BigRotComp.WorldLocation, " " + BigRotComp.RelativeRotation.Roll + "\n\n" + BigRotComp.Velocity);
		if (bOuterIsSnappedToBlood != bOuterWasSnappedToBlood && bShouldTriggerEvents)
		{
			if (bOuterIsSnappedToBlood)
				USanctuaryBloodGateEffectEventHandler::Trigger_AlignOuterWithBlood(this, GetBothPlayerData());
			else
				USanctuaryBloodGateEffectEventHandler::Trigger_UnalignOuterWithBlood(this, GetBothPlayerData());
			bOuterWasSnappedToBlood = bOuterIsSnappedToBlood;
		}
	}

	private void ManualUpdateSmallRotation(float DeltaSeconds)
	{
		float Force = 0.0;
		bool bBirdActive = bLightBirdActive || DevTogglesBloodGate::PretendBirdActive.IsEnabled();
		bool bFishActive = bDarkPortalActive || DevTogglesBloodGate::PretendFishActive.IsEnabled();
		bool bBothActive = bBirdActive && bFishActive;
		if (bBothActive)
		{
			bInnerIsSnappedToOuter = false;
			Force = -StrongRotationForce;
		}

		if (DevTogglesBloodGate::DebugDraw.IsEnabled()) 
			Debug::DrawDebugString(SmallRotComp.WorldLocation, "Roll " + SmallRotComp.RelativeRotation.Roll + "\n\n Force " + AccBigRotForce.Value);

		bool bShouldBeSnappedToOuter = !bBothActive && Math::IsNearlyEqual(SmallRotComp.RelativeRotation.Roll, 0.0, InnerSlideIntoPlaceDegreeTolerance);// && Math::IsNearlyEqual(AccSmallRotForce.Value, 0.0, CountAsStoppedTreshold);
		if (bInnerIsSnappedToOuter || bShouldBeSnappedToOuter)
		{
			if (!bInnerWasSnappedToOuter && bShouldTriggerEvents)
				USanctuaryBloodGateEffectEventHandler::Trigger_AlignInnerWithOuterWheel(this, GetBothPlayerData());

			bInnerIsSnappedToOuter = true;
			bInnerWasSnappedToOuter = bInnerIsSnappedToOuter;

			const float DurationMultiplier = 1.0 / SnapIntoPlaceDuration;
			float TimeSinceSlideStart = Time::GameTimeSeconds - SmallStartSlideIntoPladeTimestamp;
			float Alpha = Math::Saturate(TimeSinceSlideStart * DurationMultiplier);
			if (SmallStartSlideIntoPlaceRotRoll < 0.0)
			{
				float Diff = Math::Lerp(SmallStartSlideIntoPlaceRotRoll, 0.0, Alpha) - SmallRotComp.RelativeRotation.Roll;
				SmallRotComp.ApplyAngularMovement(Math::DegreesToRadians(Diff * -1.0));
			}
			if (SmallStartSlideIntoPlaceRotRoll > 0.0)
			{
				float Diff = Math::Lerp(SmallStartSlideIntoPlaceRotRoll, 0.0, Alpha) - SmallRotComp.RelativeRotation.Roll;
				SmallRotComp.ApplyAngularMovement(Math::DegreesToRadians(Diff * -1.0));
			}
			AccSmallRotForce.SnapTo(0.0);
		}
		else if (!bInnerIsSnappedToOuter && bInnerWasSnappedToOuter && bShouldTriggerEvents)
		{
			USanctuaryBloodGateEffectEventHandler::Trigger_UnalignInnerWithOuterWheel(this, GetBothPlayerData());
		}

		if (!bInnerIsSnappedToOuter)
		{
			AccSmallRotForce.AccelerateTo(Force * NoFauxForceMultiplier, 1.0, DeltaSeconds);
			float AddedRoll = AccSmallRotForce.Value * DeltaSeconds;
			SmallRotComp.ApplyAngularMovement(AddedRoll);
			SmallStartSlideIntoPlaceRotRoll = SmallRotComp.RelativeRotation.Roll;
			SmallStartSlideIntoPladeTimestamp = Time::GameTimeSeconds;	
		}

		bInnerWasSnappedToOuter = bInnerIsSnappedToOuter;
	}

	private void ManualUpdateBigRotationViaAbilities(float DeltaSeconds)
	{
		// OVERRIDE ROLL TARGET - auto align!
		float Force = 0.0;
		bool bSnapping = false;
		bool bBirdActive = bLightBirdActive || DevTogglesBloodGate::PretendBirdActive.IsEnabled();
		bool bFishActive = bDarkPortalActive || DevTogglesBloodGate::PretendFishActive.IsEnabled();
		bool bBothActive = bBirdActive && bFishActive;
		bool bAnyActive = bBirdActive || bFishActive;
		if (bAnyActive)
		{
			Force = StrongRotationForce;
			if (bBothActive)
				Force = WeakRotationForce * 0.5;
			else if (bBirdActive) 
				Force *= -1.0;
		}
		else if (Math::IsNearlyEqual(BigRotComp.RelativeRotation.Roll, 0.0, SlideIntoPlaceDegreeTolerance))
		{
			const float DurationMultiplier = 1.0 / SnapIntoPlaceDuration;
			float TimeSinceSlideStart = Time::GameTimeSeconds - BigStartSlideIntoPladeTimestamp;
			float Alpha = Math::Saturate(TimeSinceSlideStart * DurationMultiplier);
			if (BigStartSlideIntoPlaceRotRoll < 0.0)
			{
				float Diff = Math::Lerp(BigStartSlideIntoPlaceRotRoll, 0.0, Alpha) - BigRotComp.RelativeRotation.Roll;
				BigRotComp.ApplyAngularMovement(Math::DegreesToRadians(Diff * -1.0));
			}
			if (BigStartSlideIntoPlaceRotRoll > 0.0)
			{
				float Diff = Math::Lerp(BigStartSlideIntoPlaceRotRoll, 0.0, Alpha) - BigRotComp.RelativeRotation.Roll;
				BigRotComp.ApplyAngularMovement(Math::DegreesToRadians(Diff * -1.0));
			}
			bSnapping = true;
			AccBigRotForce.SnapTo(0.0);
		}



		if (!bSnapping)
		{
			AccBigRotForce.AccelerateTo(Force * NoFauxForceMultiplier, 1.0, DeltaSeconds);
			float AddedRoll = AccBigRotForce.Value * DeltaSeconds;
			BigRotComp.ApplyAngularMovement(AddedRoll);
			BigStartSlideIntoPlaceRotRoll = BigRotComp.RelativeRotation.Roll;
			BigStartSlideIntoPladeTimestamp = Time::GameTimeSeconds;
		}

		bOuterIsSnappedToBlood = Math::IsNearlyEqual(BigRotComp.RelativeRotation.Roll, 0.0, CountAsStoppedTreshold) && Math::IsNearlyEqual(AccBigRotForce.Value, 0.0, CountAsStoppedTreshold);
		if (DevTogglesBloodGate::DebugDraw.IsEnabled()) 
		{
			Debug::DrawDebugString(BigRotComp.WorldLocation, "Roll " + BigRotComp.RelativeRotation.Roll + "\n\n Force " + AccBigRotForce.Value);
			FVector2D LocalAutoAngleDirection = Math::AngleRadiansToDirection(Math::DegreesToRadians(SlideIntoPlaceDegreeTolerance));
			float Lenght = 800.0;
			FVector Forwards = ActorRightVector * 150.0;
			FVector Offset = ActorUpVector * LocalAutoAngleDirection.X * Lenght * -1.0;
			Offset += ActorForwardVector * LocalAutoAngleDirection.Y * Lenght;
			Debug::DrawDebugLine(BigRotComp.WorldLocation + Forwards, BigRotComp.WorldLocation + Forwards + Offset, ColorDebug::Yellow, 5.0, 0.0, true);
			Offset -= ActorForwardVector * LocalAutoAngleDirection.Y * Lenght * 2.0;
			Debug::DrawDebugLine(BigRotComp.WorldLocation + Forwards, BigRotComp.WorldLocation + Forwards + Offset, ColorDebug::Yellow, 5.0, 0.0, true);
			Debug::DrawDebugLine(BigRotComp.WorldLocation + Forwards, BigRotComp.WorldLocation + Forwards + BigRotComp.UpVector * - 1.0 * Lenght, ColorDebug::Cyan, 5.0, 0.0, true);
			Debug::DrawDebugLine(SmallRotComp.WorldLocation + Forwards, SmallRotComp.WorldLocation + Forwards + SmallRotComp.UpVector * - 1.0 * Lenght * 0.6, ColorDebug::Magenta, 5.0, 0.0, true);
		}
		if (bOuterIsSnappedToBlood != bOuterWasSnappedToBlood && bShouldTriggerEvents)
		{
			if (bOuterIsSnappedToBlood)
				USanctuaryBloodGateEffectEventHandler::Trigger_AlignOuterWithBlood(this, GetBothPlayerData());
			else
				USanctuaryBloodGateEffectEventHandler::Trigger_UnalignOuterWithBlood(this, GetBothPlayerData());
			bOuterWasSnappedToBlood = bOuterIsSnappedToBlood;
		}
	}

	private FSanctuaryBloodGateBothPlayersEffectEventData GetBothPlayerData()
	{
		FSanctuaryBloodGateBothPlayersEffectEventData Data;
		Data.Mio = Game::Mio;
		Data.Zoe = Game::Zoe;
		return Data;
	}

	private void PlayForceFeedback()
	{
		float FFStrength = 0.0;
		float AddedFF = 0.0;

		if (bDarkPortalActive || bLightBirdActive)
			FFStrength = 0.5;
		if (bDarkPortalActive && bLightBirdActive)
			AddedFF = 0.2;

		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 5.0) * FFStrength * 0.4 + AddedFF;
		FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * 5.0) * FFStrength * 0.4 + AddedFF;

		for (auto Player : Game::Players)
		{
			Player.SetFrameForceFeedback(FF);
		}
	}
};