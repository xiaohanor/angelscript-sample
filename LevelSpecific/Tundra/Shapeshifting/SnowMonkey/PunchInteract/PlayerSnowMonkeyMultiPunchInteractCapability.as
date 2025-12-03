class UTundraPlayerSnowMonkeyMultiPunchInteractCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract);

	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract);

	UPlayerMovementComponent MoveComp;
	UTundraPlayerSnowMonkeyComponent MonkeyComp;
	UPlayerTargetablesComponent TargetableComp;
	USteppingMovementData Movement;

	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent CurrentTargetable;

	const float LerpDuration = 0.2;
	const float TotalDuration = 1;
	FTransform TargetTransform;
	FTransform OriginalTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		TargetableComp = UPlayerTargetablesComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MonkeyComp.CurrentPunchInteractTargetable == nullptr)
			return false;

		if(MonkeyComp.CurrentPunchInteractTargetable.AnimationType != ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(Time::GetGameTimeSince(MonkeyComp.TimeOfPunch) > TotalDuration)
			return true;

		// if(PlayerWantsToLeavePunchInteract())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CurrentTargetable = MonkeyComp.CurrentPunchInteractTargetable;
		TargetTransform = CurrentTargetable.GetTargetSnowMonkeyTransform();
		OriginalTransform = Player.ActorTransform;
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeySinglePunchInteract, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, TundraShapeshiftingTags::SnowMonkeyPunchInteract, this);
		MonkeyComp.CurrentPunchInteractAnimationType = ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MonkeyComp.FrameOfStopPunch = Time::FrameNumber;
		MonkeyComp.CurrentPunchInteractTargetable = nullptr;
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeySinglePunchInteract, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		MonkeyComp.CurrentPunchInteractAnimationType = ETundraPlayerSnowMonkeyPunchInteractAnimationType::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Alpha = ActiveDuration / LerpDuration;
				Alpha = Math::Saturate(Alpha);
				Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);
				FVector CurrentLocation = Math::Lerp(OriginalTransform.Location, TargetTransform.Location, Alpha);
				FQuat CurrentRotation = FQuat::Slerp(OriginalTransform.Rotation, TargetTransform.Rotation, Alpha);

				Movement.AddDelta(CurrentLocation - Player.ActorLocation, EMovementDeltaType::HorizontalExclusive);
				Movement.SetRotation(CurrentRotation);

				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
			}
			else
			{
				if(MoveComp.HasGroundContact())
					Movement.ApplyCrumbSyncedGroundMovement();
				else
					Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMoveAndRequestLocomotion(Movement, n"InteractPunch");
		}
	}

	bool PlayerWantsToLeavePunchInteract() const
	{
		// We can't leave if we haven't entered the combo window yet
		if(!MonkeyComp.bInPunchInteractComboWindow)
			return false;

		if(!MoveComp.MovementInput.IsNearlyZero())
			return true;

		if(WasActionStarted(ActionNames::MovementJump))
			return true;

		return false;
	}
}