class UTundraPlayerSnowMonkeyMultiPunchInteractPunchCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract);

	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyPunchInteract);
	default BlockExclusionTags.Add(TundraShapeshiftingTags::SnowMonkeyMultiPunchInteract);

	UTundraPlayerSnowMonkeyComponent MonkeyComp;
	UPlayerTargetablesComponent TargetableComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MonkeyComp = UTundraPlayerSnowMonkeyComponent::Get(Player);
		TargetableComp = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundraPlayerSnowMonkeyPunchInteractActivatedParams& Params) const
	{
		if(!WasActionStartedDuringTime(ActionNames::PrimaryLevelAbility, 0.2))
			return false;

		auto Targetable = TargetableComp.GetPrimaryTarget(UTundraPlayerSnowMonkeyPunchInteractTargetableComponent);

		if(Targetable == nullptr)
			return false;

		if(Targetable.AnimationType != ETundraPlayerSnowMonkeyPunchInteractAnimationType::Multi)
			return false;

		// if(MonkeyComp.CurrentPunchInteractTargetable == nullptr && Time::GetGameTimeSince(MonkeyComp.TimeOfPunch) < 1.0)
		// 	return false;

		if(MonkeyComp.CurrentPunchInteractTargetable != nullptr && !MonkeyComp.bInPunchInteractComboWindow)
		 	return false;

		Params.Targetable = Targetable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundraPlayerSnowMonkeyPunchInteractActivatedParams Params)
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big);
		MonkeyComp.CurrentPunchInteractTargetable = Params.Targetable;
		MonkeyComp.TimeOfPunch = Time::GetGameTimeSeconds();
		MonkeyComp.bHasPunched = false;
		MonkeyComp.PunchInteractAnimData.bPunchingThisFrame = true;
		UTundraPlayerSnowMonkeyEffectHandler::Trigger_OnPunchInteractMultiPunchTriggered(MonkeyComp.SnowMonkeyActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MonkeyComp.PunchInteractAnimData.bPunchingThisFrame = false;
	}
}