class UTundraPlayerTreeGuardianRangedLifeGivingCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default CapabilityTags.Add(TundraRangedInteractionTags::RangedInteractionInteraction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLifeGiving);

	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerTreeGuardianSettings Settings;

	UTundraLifeReceivingComponent Current;
	UTundraTreeGuardianRangedInteractionTargetableComponent InteractionTargetable;
	UPlayerAimingComponent AimComp;
	float RootsGrowDuration;
	float CurrentSize;
	USceneComponent RootsOrigin;
	USceneComponent RootsDestination;

	UTundraPlayerTreeGuardianRangedInteractionCrosshairWidget CrosshairWidget;
	ATundraRangedLifeGivingActor RangedLifeActor;

	// Only used for temp debug root growing
	bool bTempHasBeenActive = false;

	bool bHasStartedInteractingDuringHold = false;
	FVector OriginalLocationToTargetable;
	FVector TargetLocationToTargetable;
	float TargetableLerpDuration;
	bool bMoveHorizontally = false;
	float PreviousHorizontalAlpha;
	float PreviousVerticalAlpha;
	TOptional<float> TimeOfStartHoldingInput;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		AimComp = UPlayerAimingComponent::Get(Player);
		TundraShapeshiftingStatics::StayInLifeGiving.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(IsActioning(ActionNames::PrimaryLevelAbility))
		{
			if(!TimeOfStartHoldingInput.IsSet())
				TimeOfStartHoldingInput.Set(Time::GetGameTimeSeconds());
		}
		else
		{
			TimeOfStartHoldingInput.Reset();
		}

		if(!bTempHasBeenActive)
			return;

		FVector CurrentDestination = FVector::ZeroVector;
		if(IsActive())
		{
			float Alpha = ActiveDuration / RootsGrowDuration;
			Alpha = Math::Min(Alpha, 1.0);
			CurrentDestination = Math::Lerp(RootsOrigin.WorldLocation, RootsDestination.WorldLocation, Alpha);
			// Debug::DrawDebugLine(RootsOrigin.WorldLocation, CurrentDestination, FLinearColor::Green, 15.0);
		}
		else if(DeactiveDuration < RootsGrowDuration)
		{
			float Alpha = DeactiveDuration / RootsGrowDuration;
			Alpha = Math::Min(Alpha, 1.0);
			CurrentDestination = Math::Lerp(RootsDestination.WorldLocation, RootsOrigin.WorldLocation, Alpha);
			// Debug::DrawDebugLine(RootsOrigin.WorldLocation, CurrentDestination, FLinearColor::Green, 15.0);
		}
		else
		{
			CurrentDestination = RootsDestination.WorldLocation;
		}
		
		if(TreeGuardianComp != nullptr)
		{
			TreeGuardianComp.CurrentRangedLifeGivingRootEndLocation = CurrentDestination;
			TreeGuardianComp.RootsDestination = RootsDestination;
		}

	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerTreeGuardianRangedLifeGivingActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(DeactiveDuration < 0.3)
			return false;

		if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
		{
			// if(Player.IsCapabilityTagBlocked(TundraShapeshiftingTags::ShapeshiftingInput))
			// 	return false;

			return false;
		}

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
		{
			if(TreeGuardianComp.RangedInteractionTargetableToForceEnter == nullptr)
				return false;

			if(TreeGuardianComp.RangedInteractionTargetableToForceEnter.InteractionType != ETundraTreeGuardianRangedInteractionType::LifeGive)
				return false;

			Params.Targetable = TreeGuardianComp.RangedInteractionTargetableToForceEnter;
			return true;
		}

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.IsDisabledForPlayer(Player))
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType != ETundraTreeGuardianRangedInteractionType::LifeGive)
			return false;

		if(!TimeOfStartHoldingInput.IsSet())
			return false;

		// if(Time::GetGameTimeSince(TimeOfStartHoldingInput.Value) < 0.15)
		// 	return false;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
		 	return false;

		Params.Targetable = TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		bool bCancelled = !IsActioning(ActionNames::PrimaryLevelAbility);
		if(TundraShapeshiftingStatics::StayInLifeGiving.IsEnabled())
			bCancelled = WasActionStarted(ActionNames::Cancel);

		if(!InteractionTargetable.bBlockCancel && bCancelled)
			return true;

		if(InteractionTargetable.bForceExit)
			return true;

		if(InteractionTargetable.IsDisabled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerTreeGuardianRangedLifeGivingActivatedParams Params)
	{
		bHasStartedInteractingDuringHold = false;
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		TreeGuardianComp.AddLifeGivingPostProcessInstigator(this);

		bTempHasBeenActive = true;
		Current = UTundraLifeReceivingComponent::Get(Params.Targetable.Owner);
		TreeGuardianComp.CurrentLifeReceivingComp = Current;
		TreeGuardianComp.bCurrentLifeGiveIsRanged = true;
		InteractionTargetable = Params.Targetable;

		PreviousHorizontalAlpha = Current.HorizontalAlpha;
		PreviousVerticalAlpha = Current.VerticalAlpha;

		bMoveHorizontally = false;
		if(IsWithinMoveOutCone())
		{
			bMoveHorizontally = true;
			FVector Origin = Player.ActorLocation;
			FVector Destination = GetMoveOutConeTargetWorldLocation();
			Destination.Z = Origin.Z;
			TargetableLerpDuration = Origin.Distance(Destination) / InteractionTargetable.LifeGivingMoveOutSpeed;

			if(InteractionTargetable.bLifeGivingMoveOutConeRelativeToTargetable)
			{
				OriginalLocationToTargetable = InteractionTargetable.WorldTransform.InverseTransformPositionNoScale(Origin);
				TargetLocationToTargetable = InteractionTargetable.WorldTransform.InverseTransformPositionNoScale(Destination);
			}
			else
			{
				OriginalLocationToTargetable = Origin;
				TargetLocationToTargetable = Destination;
			}
		}
		
		RangedLifeActor = Cast<ATundraRangedLifeGivingActor>(Current.Owner);

		TreeGuardianComp.RangedInteractionTargetableToForceEnter = nullptr;
		TreeGuardianComp.CurrentRangedLifeGivingTargetable = Params.Targetable;

		CrosshairWidget = TreeGuardianComp.TargetedRangedInteractionCrosshair;
		if(CrosshairWidget != nullptr)
			CrosshairWidget.OnInteractStart(ETundraTreeGuardianRangedInteractionType::LifeGive, Params.Targetable);

		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		
		TreeGuardianComp.bEnteringLifeGiving = true;
		CurrentSize = 0.0;

		if(TundraShapeshiftingStatics::StayInLifeGiving.IsEnabled() && !InteractionTargetable.bBlockCancel)
			Player.ShowCancelPrompt(this);

		RootsOrigin = TreeGuardianComp.TreeGuardianActor.GetRangedLifeGiverVFX_RightHand();
		RootsDestination = InteractionTargetable;
		RootsGrowDuration = RootsOrigin.WorldLocation.Distance(RootsDestination.WorldLocation) / Settings.RangedLifeGivingRootsGrowSpeed;
		InteractionTargetable.CommitInteract();

		FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams EffectParams;
		EffectParams.GrowTime = RootsGrowDuration;
		EffectParams.InteractionType = ETundraTreeGuardianRangedInteractionType::LifeGive;
		EffectParams.RootsOriginPoint = RootsOrigin;
		EffectParams.RootsTargetPoint = RootsDestination;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnStartGrowingOutRangedInteractionRoots(TreeGuardianComp.TreeGuardianActor, EffectParams);

		FTundraPlayerTreeGuardianLifeGivingEffectParams EffectParams2;
		EffectParams2.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::Ranged;
		EffectParams2.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingEntering(TreeGuardianComp.TreeGuardianActor, EffectParams2);

		if(RangedLifeActor != nullptr)
		{
			FTundraRangedLifeGivingActorOnStartInteractEffectParams EffectParams3;
			EffectParams3.DurationUntilStartLifeGive = RootsGrowDuration;
			UTundraRangedLifeGivingActorEffectHandler::Trigger_OnEnterInteract(RangedLifeActor, EffectParams3);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.SetActorVelocity(FVector::ZeroVector);
		TreeGuardianComp.RemoveLifeGivingPostProcessInstigator(this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		if(CrosshairWidget != nullptr)
			CrosshairWidget.OnInteractStop(ETundraTreeGuardianRangedInteractionType::LifeGive, InteractionTargetable);

		TreeGuardianComp.CurrentRangedLifeGivingTargetable = nullptr;

		// If a game over is triggered current is destroyed because everything reloads
		if(Current != nullptr)
		{
			Current.StopLifeGiving(ETundraPlayerTreeGuardianLifeGivingType::Ranged, false);
			Current.bForceExit = false;
		}

		FTundraPlayerTreeGuardianLifeGivingEffectParams LifeGivingParams;
		LifeGivingParams.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::Ranged;
		LifeGivingParams.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingStopped(TreeGuardianComp.TreeGuardianActor, LifeGivingParams);

		if(RangedLifeActor != nullptr)
		{
			UTundraRangedLifeGivingActorEffectHandler::Trigger_OnLifeGivingStopped(RangedLifeActor);
		}

		Current = nullptr;
		TreeGuardianComp.CurrentLifeReceivingComp = nullptr;
		TreeGuardianComp.TimeOfExitLifeGiving = Time::GetGameTimeSeconds();
		RangedLifeActor = nullptr;

		// If a game over is triggered InteractionTargetable is destroyed because everything reloads
		if(InteractionTargetable != nullptr)
		{
			InteractionTargetable.StopInteract();

			if(!InteractionTargetable.bBlockCancel)
				Player.RemoveCancelPromptByInstigator(this);
		}

		TreeGuardianComp.bCurrentlyLifeGiving = false;
		TreeGuardianComp.bEnteringLifeGiving = false;

		FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params;
		Params.GrowTime = RootsGrowDuration;
		Params.InteractionType = ETundraTreeGuardianRangedInteractionType::LifeGive;
		Params.RootsOriginPoint = RootsOrigin;
		Params.RootsTargetPoint = RootsDestination;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnStartGrowingInRangedInteractionRoots(TreeGuardianComp.TreeGuardianActor, Params);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(bMoveHorizontally)
				{
					float Alpha = ActiveDuration / TargetableLerpDuration;
					Alpha = Math::Saturate(Alpha);
					Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
					FVector NewLocation = Math::Lerp(OriginalLocationToTargetable, TargetLocationToTargetable, Alpha);

					if(InteractionTargetable.bLifeGivingMoveOutConeRelativeToTargetable)
						NewLocation = InteractionTargetable.WorldTransform.TransformPositionNoScale(NewLocation);

					Movement.AddDelta(NewLocation - Player.ActorLocation, EMovementDeltaType::Horizontal);
				}

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
				FVector ForwardDirection = (RootsDestination.WorldLocation - Player.ActorLocation).GetSafeNormal();
				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, ForwardDirection), 15.0);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			FName Feature = n"RangedLifeGiving";
			if(Current.bOverrideFeatureTag)
				Feature = Current.OverrideFeatureTag;
			else if(RangedLifeActor != nullptr && RangedLifeActor.bOverrideFeatureTag)
				Feature = RangedLifeActor.OverrideFeatureTag;

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Feature);
		}

		TreeGuardianComp.LifeGiveAnimData.LifeGivingHorizontalAlpha = Current.HorizontalAlpha;
		TreeGuardianComp.LifeGiveAnimData.LifeGivingVerticalAlpha = Current.VerticalAlpha;

		if(!HasControl())
			return;

		// Check if roots have reached life giving component, if not, don't allow player to life give.
		if(ActiveDuration < RootsGrowDuration)
			return;

		if(!Current.IsCurrentlyLifeGiving())
			CrumbStartLifeGiving();

		if(!Current.bCurrentlyInteractingDuringLifeGive && IsInputEnabled() && IsActioning(ActionNames::SecondaryLevelAbility))
		{
			Current.TryStartInteract();
		}

		if(Current.bCurrentlyInteractingDuringLifeGive && (!IsInputEnabled() || !IsActioning(ActionNames::SecondaryLevelAbility)))
		{
			Current.TryStopInteract();
		}

		FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if(!IsInputEnabled())
			MovementRaw = FVector2D::ZeroVector;

		Current.SetRawInput(MovementRaw);

		ClampMovementInputForForceFeedback(MovementRaw, DeltaTime);
		HandleForceFeedback(MovementRaw, DeltaTime);

		PreviousHorizontalAlpha = Current.HorizontalAlpha;
		PreviousVerticalAlpha = Current.VerticalAlpha;
	}

	void ClampMovementInputForForceFeedback(FVector2D& MovementRaw, float DeltaTime)
	{
		if(!Current.IsHorizontalForceFeedbackEnabled())
			MovementRaw.Y = 0.0;
		else
		{
			ETundraLifeReceivingForceFeedbackMode Mode = Current.GetHorizontalForceFeedbackMode();
			if(Mode == ETundraLifeReceivingForceFeedbackMode::BasedOnAlpha)
			{
				float Speed = ((Current.HorizontalAlpha - PreviousHorizontalAlpha) / DeltaTime);
				float SpeedAlpha = Speed / Current.HorizontalAlphaSettings.GetTheoreticalMaxSpeed();
				SpeedAlpha = Math::Abs(SpeedAlpha);
				if(SpeedAlpha < 0.01)
					SpeedAlpha = 0.0;
				else
					SpeedAlpha = Math::Max(SpeedAlpha, 0.2);
				
				MovementRaw.Y = SpeedAlpha;
			}

			MovementRaw.Y *= Current.HorizontalAlphaSettings.ForceFeedbackMultiplier;
		}

		if(!Current.IsVerticalForceFeedbackEnabled())
			MovementRaw.X = 0.0;
		else
		{
			ETundraLifeReceivingForceFeedbackMode Mode = Current.GetVerticalForceFeedbackMode();
			if(Mode == ETundraLifeReceivingForceFeedbackMode::BasedOnAlpha)
			{
				float Speed = ((Current.VerticalAlpha - PreviousVerticalAlpha) / DeltaTime);
				float SpeedAlpha = Speed / Current.VerticalAlphaSettings.GetTheoreticalMaxSpeed();
				SpeedAlpha = Math::Abs(SpeedAlpha);
				if(SpeedAlpha < 0.01)
					SpeedAlpha = 0.0;
				else
					SpeedAlpha = Math::Max(SpeedAlpha, 0.2);
				
				MovementRaw.X = SpeedAlpha;
			}

			MovementRaw.X *= Current.VerticalAlphaSettings.ForceFeedbackMultiplier;
		}
	}

	bool IsInputEnabled() const
	{
		return !Player.IsCapabilityTagBlocked(CapabilityTags::Input);
	}

	void HandleForceFeedback(FVector2D MovementRaw, float DeltaTime)
	{
		float Target = MovementRaw.Size();
		if(Target > CurrentSize)
			CurrentSize = Math::FInterpTo(CurrentSize, Target, DeltaTime, Settings.ForceFeedbackInterpSpeed);
		else
			CurrentSize = Target;
		
		FHazeFrameForceFeedback Feedback;
		float CurrentMultiplier = Math::NormalizeToRange(CurrentSize, Settings.ForceFeedbackStickDeadzone, 1.0);
		float CurrentSinValue = (Math::Sin((Time::GetGameTimeSeconds() * TWO_PI) / Settings.ForceFeedbackSinWaveDuration) + 1.0) * 0.5;
		CurrentSinValue = Math::Lerp(Settings.ForceFeedbackMinSinValue, 1.0, CurrentSinValue);
		Feedback.LeftMotor = CurrentMultiplier * Settings.ForceFeedbackMaxStrength * CurrentSinValue;
		Player.SetFrameForceFeedback(Feedback);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartLifeGiving()
	{
		InteractionTargetable.StartInteract();
		Current.StartLifeGiving(ETundraPlayerTreeGuardianLifeGivingType::Ranged, false);
		TreeGuardianComp.bCurrentlyLifeGiving = true;
		TreeGuardianComp.bEnteringLifeGiving = false;

		FTundraPlayerTreeGuardianLifeGivingEffectParams Params;
		Params.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::Ranged;
		Params.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingStarted(TreeGuardianComp.TreeGuardianActor, Params);

		if(RangedLifeActor != nullptr)
		{
			UTundraRangedLifeGivingActorEffectHandler::Trigger_OnLifeGivingStarted(RangedLifeActor);
		}

		TreeGuardianComp.TriggerRangedInteractionRootsHitSurfaceEffectEvent(InteractionTargetable, ETundraTreeGuardianRangedInteractionType::LifeGive);
	}

	bool IsWithinMoveOutCone() const
	{
		if(!InteractionTargetable.bLifeGivingMoveOutCone)
			return false;

		FVector FlatDirectionToPlayer = (Player.ActorLocation - InteractionTargetable.WorldLocation).GetSafeNormal2D();
		float AngleDegrees = FlatDirectionToPlayer.GetAngleDegreesTo(InteractionTargetable.ForwardVector);
		if(AngleDegrees > InteractionTargetable.LifeGivingMoveOutConeAngleDegrees * 0.5)
			return false;

		float DistSqrXY = Player.ActorLocation.DistSquaredXY(InteractionTargetable.WorldLocation);
		float DistSqr = Player.ActorLocation.DistSquared(InteractionTargetable.WorldLocation);
		if(DistSqr < Math::Square(InteractionTargetable.MinimumDistance))
			return false;

		if(DistSqrXY > Math::Square(InteractionTargetable.LifeGivingMoveOutConeRadius))
			return false;

		return true;
	}

	FVector GetMoveOutConeTargetWorldLocation() const
	{
		return InteractionTargetable.WorldLocation + (Player.ActorLocation - InteractionTargetable.WorldLocation).GetSafeNormal2D() * InteractionTargetable.LifeGivingMoveOutConeRadius;
	}
}

struct FTundraPlayerTreeGuardianRangedLifeGivingActivatedParams
{
	UTundraTreeGuardianRangedInteractionTargetableComponent Targetable;
}