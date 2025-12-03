struct FDragonSwordPinActivationParams
{
	UPrimitiveComponent GroundContactComponent;
}

class UDragonSwordPinToGroundActiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DragonSwordCapabilityTags::DragonSwordPinToGround);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 80;

	default DebugCategory = SummitDebugCapabilityTags::DragonSword;

	UDragonSwordPinToGroundComponent PinComp;
	UPlayerMovementComponent MoveComp;
	USteppingMovementData Movement;

	UDragonSwordUserComponent DragonSwordComp;

	FVector AccumulatedTranslation;

	USceneComponent FollowComponent;
	float FFIntensity;
	float TargetIntensity = 0.15;

	FVector RelativeUp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PinComp = UDragonSwordPinToGroundComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDragonSwordPinActivationParams& Params) const
	{
		if (MoveComp.HasMovedThisFrame())
			return false;

		if (!PinComp.bCanAttach)
			return false;

		if (PinComp.State != EDragonSwordPinToGroundState::None)
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		if (PinComp.TimeOnPinnableGround < PinComp.DelayBeforeAttaching)
			return false;

		if (MoveComp.GroundContact.Component == nullptr)
			return false;

		Params.GroundContactComponent = MoveComp.GroundContact.Component;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PinComp.bIsFullyPinned)
		{
			if (MoveComp.HasMovedThisFrame())
				return true;

			if (!IsActioning(ActionNames::PrimaryLevelAbility))
				return true;

			// if (MoveComp.HasGroundContact() && !MoveComp.GroundContact.bIsWalkable)
			// 	return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDragonSwordPinActivationParams Params)
	{
		if (DragonSwordComp == nullptr)
			DragonSwordComp = UDragonSwordUserComponent::Get(Player);

		PinComp.bIsFullyPinned = false;
		AccumulatedTranslation = FVector::ZeroVector;
		PinComp.State = EDragonSwordPinToGroundState::Pinned;
		FollowComponent = Params.GroundContactComponent;
		MoveComp.FollowComponentMovement(FollowComponent, this, EMovementFollowComponentType::ReferenceFrame);
		PinComp.PinToGround(this, EInstigatePriority::High);
		RelativeUp = FollowComponent.WorldTransform.InverseTransformVector(Player.MovementWorldUp);
		FDragonSwordPinToGroundEnterParams EnterParams;
		EnterParams.Player = Player;
		EnterParams.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
		UDragonSwordPinToGroundEffectHandler::Trigger_OnPinToGroundEnter(Player, EnterParams);

		FFIntensity = 0.0;
		Timer::SetTimer(this, n"DelayedImpactRumble", 0.4, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PinComp.UnpinFromGround(this);

		FDragonSwordPinToGroundExitParams ExitParams;
		ExitParams.Player = Player;
		ExitParams.SwordLocation = DragonSwordComp.Weapon.ActorLocation;
		UDragonSwordPinToGroundEffectHandler::Trigger_OnPinToGroundExit(Player, ExitParams);

		MoveComp.UnFollowComponentMovement(this, EMovementUnFollowComponentTransferVelocityType::Release);
		if (IsBlocked())
			PinComp.State = EDragonSwordPinToGroundState::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > PinComp.ActivateSequenceData.Duration)
			PinComp.bIsFullyPinned = true;

		FVector WorldUp = FollowComponent.WorldTransform.TransformVector(RelativeUp);
		if (MoveComp.PrepareMove(Movement, WorldUp))
		{
			if (HasControl())
			{
				auto MovementRatioData = PinComp.ActivateSequenceData;
				FVector RootMovement = PinComp.GetRootMotion(MovementRatioData.Sequence, AccumulatedTranslation, ActiveDuration, MovementRatioData.MovementLength, MovementRatioData.Duration);
				FVector DeltaMovement = Player.ActorQuat.RotateVector(RootMovement);
				// Movement.ForceGroundedStepDownSize();
				Movement.AddDelta(DeltaMovement);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}
		}

		if (ActiveDuration > PinComp.MinTimeToDisplayTutorialWhenHeld && !PinComp.bIsTutorialComplete)
		{
			Player.RemoveTutorialPromptByInstigator(Player);
			PinComp.bIsTutorialComplete = true;
		}

		float FFFrequency = 60.0;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);

		MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"DragonSwordHoldOn");
	}

	UFUNCTION()
	void DelayedImpactRumble()
	{
		Player.PlayForceFeedback(DragonSwordComp.SwordPinImpactRumble, false, false, this);
		FFIntensity = TargetIntensity;
	}
};