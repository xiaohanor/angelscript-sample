class UTundraPlayerSnowMonkeySinglePunchInteractCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 105;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeySinglePunchInteract);

	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeySinglePunchInteract);

	UPlayerMovementComponent MoveComp;
	UTundraPlayerSnowMonkeyComponent MonkeyComp;
	UPlayerTargetablesComponent TargetableComp;
	USteppingMovementData Movement;

	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent CurrentTargetable;

	const float LerpDuration = 0.2;
	const float TotalDuration = 1.0;
	FTransform TargetTransform;
	FTransform OriginalTransform;
	bool bIsFirstFrame = true;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UPlayerMovementComponent::Get(Player);
		MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		TargetableComp = UPlayerTargetablesComponent::Get(Player);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		TargetableComp.ShowWidgetsForTargetables(UTundraPlayerSnowMonkeyPunchInteractTargetableComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerSnowMonkeyPunchInteractActivatedParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(Time::GetGameTimeSince(MonkeyComp.TimeOfPunch) < 1.0)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
			return false;

		auto Targetable = TargetableComp.GetPrimaryTarget(UTundraPlayerSnowMonkeyPunchInteractTargetableComponent);

		if(Targetable == nullptr)
			return false;

		if(Targetable.AnimationType != ETundraPlayerSnowMonkeyPunchInteractAnimationType::Single)
			return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > TotalDuration)
			return true;

		if(PlayerWantsToLeavePunchInteract())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerSnowMonkeyPunchInteractActivatedParams Params)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		bIsFirstFrame = true;
		CurrentTargetable = Params.Targetable;
		MonkeyComp.CurrentPunchInteractTargetable = CurrentTargetable;
		MonkeyComp.TimeOfPunch = Time::GetGameTimeSeconds();
		MonkeyComp.bHasPunched = false;
		TargetTransform = CurrentTargetable.GetTargetSnowMonkeyTransform();
		OriginalTransform = Player.ActorTransform;
		Player.BlockCapabilities(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		MonkeyComp.PunchInteractAnimData.bPunchingThisFrame = true;
		MonkeyComp.CurrentPunchInteractAnimationType = ETundraPlayerSnowMonkeyPunchInteractAnimationType::Single;
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnPunchInteractSinglePunchTriggered(MonkeyComp.SnowMonkeyActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MonkeyComp.FrameOfStopPunch = Time::FrameNumber;
		MonkeyComp.CurrentPunchInteractTargetable = nullptr;
		Player.UnblockCapabilities(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		MonkeyComp.PunchInteractAnimData.bPunchingThisFrame = false;
		MonkeyComp.CurrentPunchInteractAnimationType = ETundraPlayerSnowMonkeyPunchInteractAnimationType::None;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bIsFirstFrame)
		{
			MonkeyComp.PunchInteractAnimData.bPunchingThisFrame = false;
		}
		bIsFirstFrame = false;

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

struct FTundraPlayerSnowMonkeyPunchInteractActivatedParams
{
	UTundraPlayerSnowMonkeyPunchInteractTargetableComponent Targetable;
}