class UAdultDragonTailSmashWaitCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonTailSmash::Tags::AdultDragonTailSmash);

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = AdultDragonTailSmash::DefaultTickGroupOrder;
	default TickGroupSubPlacement = 1;

	USimpleMovementData Movement;

	UPlayerMovementComponent MoveComp;
	UAdultDragonTailSmashComponent SmashComp;
	UPlayerTailAdultDragonComponent DragonComp;
	UPlayerAimingComponent AimComp;

	float InitialSpeed = 0;

	bool bClearedFeedback;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		SmashComp = UAdultDragonTailSmashComponent::Get(Player);
		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Movement = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// SmashComp.State = EAdultDragonTailSmashState::Waiting;
		// InitialSpeed = Player.ActorVelocity.Size();
		Player.ApplyCameraSettings(SmashComp.SpinChargeCameraSettings, 0.5, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration/AdultDragonTailSmash::SpinChargeTime);

		SmashComp.SpinChargeTime = ActiveDuration;
		Player.ApplyManualFractionToCameraSettings(Alpha, this);
		if (AimComp.HasAimingTargetOverride())
		{
			auto AutoAimTarget = AimComp.GetAimingTarget(Player).AutoAimTarget;
			if (AutoAimTarget != nullptr)
			{
				SmashComp.SmashTargetComp = AutoAimTarget;
				SmashComp.SmashTargetPoint = AimComp.GetAimingTarget(Player).AutoAimTargetPoint;
			}
		}
	}
};