class UTundraWalkingStickMovementCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraWalkingStickMovementComponent MoveComp;
	USimpleMovementData Movement;
	UTundraLifeReceivingComponent RelevantLifeReceivingComp;
	FHazeAcceleratedFloat CurrentSpeed;
	float CurrentTurnInputSpeed = 0.0;
	FHazeAcceleratedFloat CurrentTurnSpeed;

	FTutorialPrompt TutorialPrompt;
	default TutorialPrompt.Action = ActionNames::ContextualMovement;
	default TutorialPrompt.Text = NSLOCTEXT("WalkingStick", "Steer", "Steer");
	default TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
	bool bPromptShown = false;
	bool bPromptCurrentlyOnScreen = false;
	bool bHasMovedInput = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		MoveComp = WalkingStick.MoveComp;
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(WalkingStick.CurrentState != ETundraWalkingStickState::Walking)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(WalkingStick.CurrentState != ETundraWalkingStickState::Walking)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(WalkingStick.LifeGivingActorRef != nullptr)
			RelevantLifeReceivingComp = WalkingStick.LifeGivingActorRef.LifeReceivingComp;

		UMovementStandardSettings::SetWalkableSlopeAngle(WalkingStick, 0.0, this);
		CurrentSpeed.SnapTo(WalkingStick.MoveComp.HorizontalVelocity.Size());
		CurrentTurnInputSpeed = 0.0;

		if(WalkingStick.bGameplaySpider && !bPromptShown)
		{
			Game::Zoe.ShowTutorialPrompt(TutorialPrompt, this);
			bPromptShown = true;
			bPromptCurrentlyOnScreen = true;
		}

		if(WalkingStick.bGameplaySpider)
		{
			WalkingStick.ShowScreamTutorial();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UMovementStandardSettings::ClearWalkableSlopeAngle(WalkingStick, this);
		SpeedEffect::ClearSpeedEffect(Game::Mio, this);
		SpeedEffect::ClearSpeedEffect(Game::Zoe, this);

		if(bPromptCurrentlyOnScreen)
		{
			Game::Zoe.RemoveTutorialPromptByInstigator(this);
			bPromptCurrentlyOnScreen = false;
		}

		WalkingStick.ClearScreamTutorial();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WalkingStick.bGameplaySpider && (!Math::IsNearlyZero(RelevantLifeReceivingComp.RawHorizontalInput)))
			bHasMovedInput = true;

		if(ActiveDuration > 3.0 && bPromptCurrentlyOnScreen && bHasMovedInput && WalkingStick.bScreamHasEverBeenCalled)
		{
			WalkingStick.ClearScreamTutorial();
			Game::Zoe.RemoveTutorialPromptByInstigator(this);
			bPromptCurrentlyOnScreen = false;
		}

		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				CurrentSpeed.AccelerateTo(WalkingStick.TargetSpeed, CurrentAccelerationDuration, DeltaTime);

				Movement.AddVelocity(WalkingStick.ActorForwardVector * CurrentSpeed.Value);

				float TargetWallSteerSpeed = 0.0;
				float TargetInputSpeed = 0.0;
				if(MoveComp.HasWallContact())
				{
					FVector WallRightVector = MoveComp.WallContact.ImpactNormal.CrossProduct(FVector::UpVector);
					float DirectionToSteerTowards = Math::Sign(WallRightVector.DotProduct(WalkingStick.ActorForwardVector));
					TargetWallSteerSpeed = WalkingStick.TurnInputSpeed * DirectionToSteerTowards;
				}

				float CurrentInput = GetCurrentInput();
				if(RelevantLifeReceivingComp != nullptr && (TargetWallSteerSpeed == 0.0 || Math::Sign(CurrentInput) == Math::Sign(TargetWallSteerSpeed)))
				{
					TargetInputSpeed = WalkingStick.TurnInputSpeed * CurrentInput;
				}

				float TargetSteerSpeed = TargetWallSteerSpeed + TargetInputSpeed;
				float InterpSpeed = 0.5;
				if(Math::Abs(TargetSteerSpeed) < Math::Abs(CurrentTurnInputSpeed))
					InterpSpeed = 2.0;

				CurrentTurnInputSpeed = Math::FInterpTo(CurrentTurnInputSpeed, TargetSteerSpeed, DeltaTime, InterpSpeed);
				Movement.SetRotation(WalkingStick.ActorQuat * FRotator(0.0, CurrentTurnInputSpeed * DeltaTime, 0.0).Quaternion());
				WalkingStick.AnimData.SteerInput = CurrentTurnInputSpeed / WalkingStick.TurnInputSpeed;
				
				if(WalkingStick.bGameplaySpider)
				{
					float Value = Math::GetMappedRangeValueClamped(WalkingStick.SpeedEffectSpeedRange.ConvertToVector2D(), WalkingStick.SpeedEffectAmountRange.ConvertToVector2D(), CurrentSpeed.Value);
					SpeedEffect::RequestSpeedEffect(Game::Mio, Value, this, EInstigatePriority::Normal);
					SpeedEffect::RequestSpeedEffect(Game::Zoe, Value, this, EInstigatePriority::Normal);
				}
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			WalkingStick.AnimData.SetCurrentSpeed(MoveComp.HorizontalVelocity.Size());

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"WalkingStickMovement");
		}

#if EDITOR
		if(!WalkingStick::WalkingStickInvulnerable.IsEnabled())
			return;

		TArray<FMovementHitResult> Hits = MoveComp.GetAllImpacts();
		for(FMovementHitResult Hit : Hits)
		{
			auto Obstacle = Cast<ATundraStickObstacle>(Hit.Actor);
			if(Obstacle != nullptr)
				Obstacle.BreakObstacle();
		}
#endif
	}

	float GetCurrentAccelerationDuration() const property
	{
		if(WalkingStick.bTreeGuardianInteracting && WalkingStick.bMoveFaster)
			return WalkingStick.FasterSpeedAccelerationDuration;

		return WalkingStick.WalkingStickAccelerationDuration;
	}

	float GetCurrentInput() const
	{
		if(WalkingStick.IsAutoSteering())
		{
			FSplinePosition SplinePos = WalkingStick.GetClosestAutoSteerSplinePosition();
			float RemainingDistance = 0.0;
			SplinePos.Move(20000.0, RemainingDistance);
			FVector SplineLocation = SplinePos.WorldLocation + SplinePos.WorldForwardVector * RemainingDistance;
			FVector Direction = (SplineLocation - WalkingStick.ActorLocation).GetSafeNormal();
			float Dot = WalkingStick.ActorRightVector.DotProduct(Direction);
			Dot *= 4.0;
			Dot = Math::Clamp(Dot, -1.0, 1.0);

			if(IsDebugActive())
			{
				Debug::DrawDebugSphere(SplineLocation, 100.0, 12, FLinearColor::Red, 5.0);
				PrintToScreen(f"Auto steer input: {Dot}");
			}

			return Dot;
		}

		if(!WalkingStick.bGameplaySpider)
			return 0;

		return RelevantLifeReceivingComp.RawHorizontalInput;
	}
}