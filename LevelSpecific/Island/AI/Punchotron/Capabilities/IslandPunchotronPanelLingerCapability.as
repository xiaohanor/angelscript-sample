class UIslandPunchotronPanelLingerCapability : UHazeCapability
{
	UIslandPunchotronPanelTriggerComponent PanelComp;

	AAIIslandPunchotron Punchotron;
	UIslandPunchotronSettings Settings;
	UBasicAITargetingComponent TargetComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
		TargetComp = UBasicAITargetingComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		Punchotron = Cast<AAIIslandPunchotron>(Owner);
	}


	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!PanelComp.bIsOnPanel)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (TargetComp.DistanceToTarget > 500)
			return false;
		if (Owner.IsAnyCapabilityActive(n"CobraStrike"))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!PanelComp.bIsOnPanel)
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		if (TargetComp.DistanceToTarget > 500)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UIslandPunchotronSettings::SetChaseMoveSpeed(Owner, Settings.ChaseMoveSpeed * Settings.OnPanelSlowdownFactor, this);
		UIslandPunchotronSettings::SetGroundFriction(Owner, Settings.OnPanelGroundFriction, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UIslandPunchotronSettings::ClearChaseMoveSpeed(Owner, this);
		UIslandPunchotronSettings::ClearGroundFriction(Owner, this);
	}

}