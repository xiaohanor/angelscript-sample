class UTeenDragonRollRailCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragon);
	default CapabilityTags.Add(TeenDragonCapabilityTags::TeenDragonRoll);

	default TickGroup = EHazeTickGroup::Gameplay;

	default DebugCategory = SummitDebugCapabilityTags::TeenDragon;

	UPlayerTailTeenDragonComponent DragonComp;
	UTeenDragonRollRailComponent RollRailComp;
	UTeenDragonRollComponent RollComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);
		RollRailComp = UTeenDragonRollRailComponent::Get(Player);
		RollComp = UTeenDragonRollComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollRailComp.IsInRollRail())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollRailComp.IsInRollRail())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(RollRailComp.CurrentRollRail.Value.OverridingRailSettings != nullptr)
			Player.ApplySettings(RollRailComp.CurrentRollRail.Value.OverridingRailSettings, this, EHazeSettingsPriority::Script);
		
		RollComp.RollingInstigators.AddUnique(this);
		RollComp.BlockKnockBackInstigators.AddUnique(this);

		RollRailComp.CurrentRollRail.Value.OnRailEntered.Broadcast();
		UTeenDragonRollRailEventHandler::Trigger_OnEnterRail(Player, FTeenDragonRollRailEventParams(RollRailComp.CurrentRollRail.Value));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(RollRailComp.CurrentRollRail.Value.OverridingRailSettings != nullptr)
			Player.ClearSettingsByInstigator(this);

		RollComp.RollingInstigators.RemoveSingleSwap(this);
		RollComp.BlockKnockBackInstigators.RemoveSingleSwap(this);

		RollRailComp.CurrentRollRail.Value.OnRailExited.Broadcast();
		UTeenDragonRollRailEventHandler::Trigger_OnExitRail(Player, FTeenDragonRollRailEventParams(RollRailComp.CurrentRollRail.Value));

		RollRailComp.CurrentRollRail.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};