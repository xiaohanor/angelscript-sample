class UTundraPlayerTreeGuardianGroundedLifeGivingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TundraShapeshiftingTags::TundraLifeGiving);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerShapeshiftingComponent PlayerShapeshiftingComponent;
	UPlayerTargetablesComponent PlayerTargetablesComponent;
	UTundraLifeReceivingComponent Current;
	UTundraGroundedLifeReceivingTargetableComponent CurrentTargetable;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerTreeGuardianSettings Settings;
	USteppingMovementData Movement;

	float CurrentSize;
	bool bEnterInstant;
	bool bWasForceEntered;
	bool bHasStartedInteractingDuringHold = false;
	ATundraGroundedLifeGivingActor GroundedLifeActor;
	FVector TreeGuardianLocalLocationLifeGivingActor;
	FRotator TreeGuardianLocalRotationLifeGivingActorOffset;
	float PreviousHorizontalAlpha;
	float PreviousVerticalAlpha;
	bool bShouldLerp;
	float LerpDuration;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerShapeshiftingComponent = UTundraPlayerShapeshiftingComponent::Get(Player);
		PlayerTargetablesComponent = UPlayerTargetablesComponent::Get(Player);
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
		TundraShapeshiftingStatics::StayInLifeGiving.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsBlocked() && !IsActive() && PlayerShapeshiftingComponent.CurrentShapeType == ETundraShapeshiftShape::Big)
		{
			PlayerTargetablesComponent.ShowWidgetsForTargetables(UTundraGroundedLifeReceivingTargetableComponent);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FShapeshiftingLifeGivingActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PlayerShapeshiftingComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return false;

		auto PrimaryTarget = PlayerTargetablesComponent.GetPrimaryTarget(UTundraGroundedLifeReceivingTargetableComponent);
		if (PrimaryTarget == nullptr)
			return false;

		auto LifeReceivingComp = UTundraLifeReceivingComponent::Get(PrimaryTarget.Owner);
		devCheck(LifeReceivingComp != nullptr, f"There is a UTundraLifeReceivingTargetableComponent on actor with name {PrimaryTarget.Owner.Name} but no UTundraLifeReceivingComponent");

		if (!WasActionStarted(ActionNames::PrimaryLevelAbility) && !LifeReceivingComp.bForceEnter)
			return false;

		Params.Targetable = PrimaryTarget;
		Params.LifeReceivingComp = LifeReceivingComp;

		if(LifeReceivingComp.bForceEnter)
		{
			Params.bForceEntered = true;
			Params.bEnterInstant = LifeReceivingComp.bForceEnterInstant;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FShapeshiftingLifeGivingDeactivatedParams& Params) const
	{
		if(Current.bForceExit)
		{
			Params.bForceExited = true;
			Params.bExitInstant = Current.bForceExitInstant;
			return true;
		}

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(PlayerShapeshiftingComponent.CurrentShapeType != ETundraShapeshiftShape::Big)
			return true;

		bool bShouldBlockCancel = Current.bBlockCancel || Current.bForceBlockCancel;

		bool bCancelled = !IsActioning(ActionNames::PrimaryLevelAbility);
		if(TundraShapeshiftingStatics::StayInLifeGiving.IsEnabled())
			bCancelled = WasActionStarted(ActionNames::Cancel);

		if(!bShouldBlockCancel && bCancelled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FShapeshiftingLifeGivingActivatedParams Params)
	{
		bHasStartedInteractingDuringHold = false;
		TreeGuardianComp.AddLifeGivingPostProcessInstigator(this);

		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::High);
		Current = Params.LifeReceivingComp;
		TreeGuardianComp.CurrentLifeReceivingComp = Params.LifeReceivingComp;
		TreeGuardianComp.bCurrentLifeGiveIsRanged = false;
		CurrentTargetable = Params.Targetable;
		CurrentTargetable.OnCommitInteract.Broadcast();

		PreviousHorizontalAlpha = Current.HorizontalAlpha;
		PreviousVerticalAlpha = Current.VerticalAlpha;

		GroundedLifeActor = Cast<ATundraGroundedLifeGivingActor>(Current.Owner);

		bShouldLerp = ShouldLerpToLocation();
		if(bShouldLerp)
		{
			TreeGuardianLocalLocationLifeGivingActor = TreeGuardianLerpOriginTransform.InverseTransformPositionNoScale(Player.ActorLocation);
			TreeGuardianLocalRotationLifeGivingActorOffset = TreeGuardianLerpOriginTransform.InverseTransformRotation(Player.ActorRotation);
			LerpDuration = GetTreeGuardianLerpDuration();
		}

		bWasForceEntered = Params.bForceEntered;

		Current.bForceEnter = false;

		if(!Current.bBlockCancel && !Current.bForceBlockCancel)
		{
			if(TundraShapeshiftingStatics::StayInLifeGiving.IsEnabled())
				Player.ShowCancelPrompt(this);
		}
		else
		{
			PlayerShapeshiftingComponent.AddShapeTypeBlocker(ETundraShapeshiftShape::Player, this);
		}

		CurrentSize = 0.0;
		TreeGuardianComp.bEnteringLifeGiving = true;

		bEnterInstant = Params.bEnterInstant;
		TreeGuardianComp.LifeGiveAnimData.bEnterInstant = bEnterInstant;

		FTundraPlayerTreeGuardianLifeGivingEffectParams EffectParams;
		EffectParams.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::NonRanged;
		EffectParams.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingEntering(TreeGuardianComp.TreeGuardianActor, EffectParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FShapeshiftingLifeGivingDeactivatedParams Params)
	{
		Player.SetActorVelocity(FVector::ZeroVector);
		TreeGuardianComp.RemoveLifeGivingPostProcessInstigator(this);
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
		MoveComp.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		if(bShouldLerp)
		{
			Player.MeshOffsetComponent.SnapToRelativeLocation(this, Player.MeshOffsetComponent, Player.Mesh.RelativeLocation);
			Player.Mesh.RelativeLocation = FVector::ZeroVector;
			if (IsWalkingStickLifeGiving())
				Player.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.0);
			else
				Player.MeshOffsetComponent.ResetOffsetWithLerp(this, LerpDuration);
		}

		PlayerShapeshiftingComponent.RemoveShapeTypeBlockerInstigator(this);

		// If a game over is triggered current is destroyed because everything reloads
		if(Current != nullptr)
		{
			Current.StopLifeGiving(ETundraPlayerTreeGuardianLifeGivingType::NonRanged, Params.bForceExited);
			Current.bForceExit = false;
			Current.bForceBlockCancel = false;
		}

		FTundraPlayerTreeGuardianLifeGivingEffectParams EffectParams;
		EffectParams.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::NonRanged;
		EffectParams.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingStopped(TreeGuardianComp.TreeGuardianActor, EffectParams);

		Current = nullptr;
		TreeGuardianComp.CurrentLifeReceivingComp = nullptr;
		TreeGuardianComp.TimeOfExitLifeGiving = Time::GetGameTimeSeconds();
		TreeGuardianComp.bCurrentlyLifeGiving = false;
		TreeGuardianComp.bEnteringLifeGiving = false;
		Player.RemoveCancelPromptByInstigator(this);
		GroundedLifeActor = nullptr;

		// If a game over is triggered current targetable is destroyed because everything reloads
		if(CurrentTargetable != nullptr)
		{
			CurrentTargetable.OnStopInteract.Broadcast();
			CurrentTargetable = nullptr;
		}

		TreeGuardianComp.LifeGiveAnimData.bExitInstant = Params.bExitInstant;
	}

	bool IsWalkingStickLifeGiving() const
	{
		if (Current == nullptr)
			return false;
		if (Current.Owner == nullptr)
			return false;
		if (Current.Owner.AttachParentActor == nullptr)
			return false;
		if (!Current.Owner.AttachParentActor.IsA(ATundraWalkingStick))
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				if(bShouldLerp)
				{
					float Alpha = Math::EaseInOut(0.0, 1.0, Math::Saturate(ActiveDuration / LerpDuration), 2.0);
					FVector CurrentLocalLocation = Math::Lerp(TreeGuardianLocalLocationLifeGivingActor, TreeGuardianLerpLocalOffset, Alpha);

					FVector CurrentLocation = TreeGuardianLerpOriginTransform.TransformPositionNoScale(CurrentLocalLocation);
					FRotator CurrentLocalRotation = FQuat::Slerp(TreeGuardianLocalRotationLifeGivingActorOffset.Quaternion(), FQuat::Identity, Alpha).Rotator();
					FRotator CurrentRotation = TreeGuardianLerpOriginTransform.TransformRotation(CurrentLocalRotation);

					Movement.AddDelta(CurrentLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
					Player.Mesh.RelativeLocation = Math::Lerp(FVector::ZeroVector, TreeGuardianLerpMeshOffset, Alpha);
					Movement.SetRotation(CurrentRotation);
				}

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			FName Feature = n"TreeGuardianHeal";
			if(Current.bOverrideFeatureTag)
				Feature = Current.OverrideFeatureTag;
			else if(GroundedLifeActor != nullptr && GroundedLifeActor.bOverrideFeatureTag)
				Feature = GroundedLifeActor.OverrideFeatureTag;
			
			MoveComp.ApplyMoveAndRequestLocomotion(Movement, Feature);
		}

		TreeGuardianComp.LifeGiveAnimData.LifeGivingHorizontalAlpha = Current.HorizontalAlpha;
		TreeGuardianComp.LifeGiveAnimData.LifeGivingVerticalAlpha = Current.VerticalAlpha;

		if(!HasControl())
			return;

		if(!bEnterInstant && ActiveDuration < Settings.DelayBeforeEnablingLifeGiving)
			return;

		if(!Current.IsCurrentlyLifeGiving())
			CrumbStartLifeGiving(bWasForceEntered);

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
	
	bool ShouldLerpToLocation() const
	{
		if(GroundedLifeActor != nullptr && GroundedLifeActor.bLerpTreeGuardianToPoint)
			return true;

		if(CurrentTargetable != nullptr && CurrentTargetable.bLerpTreeGuardianToPoint)
			return true;

		return false;
	}

	float GetTreeGuardianLerpDuration() const
	{
		if(CurrentTargetable != nullptr && CurrentTargetable.bLerpTreeGuardianToPoint)
			return CurrentTargetable.TreeGuardianLerpDuration;

		return GroundedLifeActor.TreeGuardianLerpDuration;
	}

	FVector GetTreeGuardianLerpLocalOffset() const property
	{
		if(CurrentTargetable != nullptr && CurrentTargetable.bLerpTreeGuardianToPoint)
			return CurrentTargetable.TreeGuardianLerpLocalOffset;

		return GroundedLifeActor.TreeGuardianLerpLocalOffset;
	}

	FVector GetTreeGuardianLerpMeshOffset() const property
	{
		if(CurrentTargetable != nullptr && CurrentTargetable.bLerpTreeGuardianToPoint)
			return CurrentTargetable.TreeGuardianLerpMeshOffset;

		return GroundedLifeActor.TreeGuardianLerpMeshOffset;
	}

	FTransform GetTreeGuardianLerpOriginTransform() const property
	{
		if(CurrentTargetable != nullptr && CurrentTargetable.bLerpTreeGuardianToPoint)
			return CurrentTargetable.WorldTransform;

		return GroundedLifeActor.ActorTransform;
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
		float CurrentSinValue = (Math::Sin(Time::GetGameTimeSeconds()) + 1.0) * 0.5;
		CurrentSinValue = Math::Lerp(Settings.ForceFeedbackMinSinValue, 1.0, CurrentSinValue);
		float Strength = CurrentMultiplier * Settings.ForceFeedbackMaxStrength * CurrentSinValue;
		Feedback.LeftMotor = Strength;
		//PrintToScreen(f"{Strength=}");
		Player.SetFrameForceFeedback(Feedback);
	}

	UFUNCTION(CrumbFunction)
	void CrumbStartLifeGiving(bool bForced)
	{
		// If the world is tearing down right as the life give is started, Current might be null on Mio's side, just return in that case
		if(Current == nullptr)
			return;

		Current.StartLifeGiving(ETundraPlayerTreeGuardianLifeGivingType::NonRanged, bForced);
		TreeGuardianComp.bCurrentlyLifeGiving = true;
		TreeGuardianComp.bEnteringLifeGiving = false;

		FTundraPlayerTreeGuardianLifeGivingEffectParams Params;
		Params.LifeGivingType = ETundraPlayerTreeGuardianLifeGivingType::NonRanged;
		Params.LifeReceivingComponent = Current;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnLifeGivingStarted(TreeGuardianComp.TreeGuardianActor, Params);
	}
}

struct FShapeshiftingLifeGivingActivatedParams
{
	UTundraGroundedLifeReceivingTargetableComponent Targetable;
	UTundraLifeReceivingComponent LifeReceivingComp;
	bool bEnterInstant = false;
	bool bForceEntered = false;
}

struct FShapeshiftingLifeGivingDeactivatedParams
{
	bool bExitInstant = false;
	bool bForceExited = false;
}