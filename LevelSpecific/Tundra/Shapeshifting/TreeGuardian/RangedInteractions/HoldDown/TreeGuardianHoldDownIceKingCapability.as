class UTundraTreeGuardianInteractionHoldDownIceKingCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;
	UTundraPlayerTreeGuardianComponent TreeGuardianComp;
	UTundraPlayerShapeshiftingComponent ShapeshiftingComp;
	UTreeGuardianHoldDownIceKingComponent HoldDownIceKingComponent;
	UTundraPlayerTreeGuardianSettings Settings;

	UTundraTreeGuardianRangedInteractionTargetableComponent InteractionTargetable;

	FVector OriginalLocationToTargetable;
	FVector TargetLocationToTargetable;
	float TargetableLerpDuration;
	bool bMoveHorizontally = false;
	bool bDone = false;
	FHazeLocomotionTransform RootMotion;

	USceneComponent RootsOrigin;
	USceneComponent RootsDestination;
	float RootsGrowDuration;
	bool bExiting = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
		TreeGuardianComp = UTundraPlayerTreeGuardianComponent::Get(Player);
		ShapeshiftingComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		HoldDownIceKingComponent = UTreeGuardianHoldDownIceKingComponent::GetOrCreate(Player);
		Settings = UTundraPlayerTreeGuardianSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraTreeGuardianInteractionHoldDownIceKingActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(ShapeshiftingComp.GetCurrentShapeType() != ETundraShapeshiftShape::Big)
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable == nullptr)
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.IsDisabledForPlayer(Player))
			return false;

		if(TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable.InteractionType != ETundraTreeGuardianRangedInteractionType::IceKingHoldDown)
			return false;

		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		Params.Targetable = TreeGuardianComp.CurrentlyFoundRangedInteractionTargetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(bDone)
			return true;

		// if(InteractionTargetable.bForceExit)
		// 	return true;

		// if(InteractionTargetable.IsDisabled())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraTreeGuardianInteractionHoldDownIceKingActivatedParams Params)
	{
		bDone = false;
		bExiting = false;
		InteractionTargetable = Params.Targetable;
		InteractionTargetable.CommitInteract();

		Player.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		if(InteractionTargetable.bIceKingHoldDownBlockDeath)
		{
			Player.BlockCapabilities(CapabilityTags::Death, this);
			Player.BlockCapabilities(n"HitReaction", this);
		}

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

		if(HasControl())
			Timer::SetTimer(this, n"CrumbStartButtonMash", 1.33);

		TreeGuardianComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.AddUFunction(this, n"OnPostAnimEvalComplete");
		Player.BlockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);

		RootsOrigin = TreeGuardianComp.TreeGuardianActor.GetRangedLifeGiverVFX_RightHand();
		RootsDestination = InteractionTargetable;
		RootsGrowDuration = RootsOrigin.WorldLocation.Distance(RootsDestination.WorldLocation) / Settings.RangedLifeGivingRootsGrowSpeed;

		// FireGrowingOutEvent();
	}

	void BroadcastGrowingOut()
	{
		FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams EffectParams;
		EffectParams.GrowTime = RootsGrowDuration;
		EffectParams.InteractionType = ETundraTreeGuardianRangedInteractionType::IceKingHoldDown;
		EffectParams.RootsOriginPoint = RootsOrigin;
		EffectParams.RootsTargetPoint = RootsDestination;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnStartGrowingOutRangedInteractionRoots(TreeGuardianComp.TreeGuardianActor, EffectParams);
	}

	void BroadcastGrowingIn()
	{
		if(bCanceledTakedown)
			return;

		FTundraPlayerTreeGuardianRangedInteractionGrowRootsEffectParams Params;
		Params.GrowTime = RootsGrowDuration;
		Params.InteractionType = ETundraTreeGuardianRangedInteractionType::IceKingHoldDown;
		Params.RootsOriginPoint = RootsOrigin;
		Params.RootsTargetPoint = RootsDestination;
		UTreeGuardianBaseEffectEventHandler::Trigger_OnStartGrowingInRangedInteractionRoots(TreeGuardianComp.TreeGuardianActor, Params);

		bCanceledTakedown = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		InteractionTargetable.StopInteract();
		TreeGuardianComp.HoldDownIceKingAnimData.bFail = false;
		TreeGuardianComp.HoldDownIceKingAnimData.bSuccess = false;
		TreeGuardianComp.HoldDownIceKingAnimData.ButtonMashProgress = 0.0;
		TreeGuardianComp.GetShapeActor().Mesh.OnPostAnimEvalComplete.Unbind(this, n"OnPostAnimEvalComplete");
		Player.UnblockCapabilities(TundraRangedInteractionTags::RangedInteractionAiming, this);
		Player.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);

		if(InteractionTargetable.bIceKingHoldDownBlockDeath)
		{
			Player.UnblockCapabilities(CapabilityTags::Death, this);
			Player.UnblockCapabilities(n"HitReaction", this);
		}	

		HoldDownIceKingComponent.OnMashCompleted.Unbind(this, n"OnButtonMashCompleted");
		HoldDownIceKingComponent.OnMashFailed.Unbind(this, n"OnButtonMashFailed");

		BroadcastGrowingIn();

		bStartedTakedown = false;
		bCanceledTakedown = false;
	}

	// delay the event until the animation is where we want it to be
	bool bStartedTakedown = false;
	bool bCanceledTakedown = false;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl() && !bExiting && InteractionTargetable.bForceExit)
		{
			CrumbOnButtonMashFailed();
		}

		// delay the broadcast until the "casting arm" is facing the boss
		if(bStartedTakedown == false)
		{
			const float RelevantDelayBefoeStartGrowing = Treeguardian::Takedown::AnimationDelays::Launch;
			if(ActiveDuration > RelevantDelayBefoeStartGrowing)
			{
				BroadcastGrowingOut();
				bStartedTakedown = true;
			}
		}

		if(HoldDownIceKingComponent.bButtonMashIsActive)
			TreeGuardianComp.HoldDownIceKingAnimData.ButtonMashProgress = HoldDownIceKingComponent.GetInterpolatedMashProgress();

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

					Movement.AddDelta(NewLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				}

				FVector CurrentDelta = RootMotion.DeltaTranslation;
				Movement.AddDeltaWithCustomVelocity(CurrentDelta, FVector::ZeroVector);

				Movement.AddGravityAcceleration();
				Movement.AddOwnerVerticalVelocity();
				FVector ForwardDirection = (InteractionTargetable.WorldLocation - Player.ActorLocation);
				Movement.InterpRotationTo(FQuat::MakeFromZX(FVector::UpVector, ForwardDirection), 15.0);
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"TreeGuardian_Attach_IceKing");
		}
	}

	UFUNCTION()
	private void OnPostAnimEvalComplete(UHazeSkeletalMeshComponentBase SkeletalMesh)
	{
		SkeletalMesh.ConsumeLastExtractedRootMotion(RootMotion);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbStartButtonMash()
	{
		HoldDownIceKingComponent.StartHoldDownIceKingButtonMash(InteractionTargetable.IceKingHoldDownButtonMashSettings, 0.5, InteractionTargetable);
		HoldDownIceKingComponent.OnMashCompleted.AddUFunction(this, n"OnButtonMashCompleted");
		HoldDownIceKingComponent.OnMashFailed.AddUFunction(this, n"OnButtonMashFailed");
		TreeGuardianComp.HoldDownIceKingAnimData.ButtonMashProgress = 0.5;
	}

	UFUNCTION()
	private void OnButtonMashCompleted(bool bIsIceKing)
	{
		TreeGuardianComp.HoldDownIceKingAnimData.bSuccess = true;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbOnButtonMashFailed()
	{
		OnButtonMashFailed();
	}
	
	UFUNCTION()
	private void OnButtonMashFailed()
	{
		bExiting = true;
		TreeGuardianComp.HoldDownIceKingAnimData.bFail = true;
		BroadcastGrowingIn();
		Timer::SetTimer(this, n"OnDone", 1.0);
	}

	UFUNCTION()
	private void OnDone()
	{
		bDone = true;
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

struct FTundraTreeGuardianInteractionHoldDownIceKingActivatedParams
{
	UTundraTreeGuardianRangedInteractionTargetableComponent Targetable;
}