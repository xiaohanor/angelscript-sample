class UBallistaHydraPlayerDuringHydraRegrowCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	UBallistaHydraActorReferencesComponent BallistaRefsComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallistaRefsComp = UBallistaHydraActorReferencesComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (BallistaRefsComp.Refs == nullptr)
			return false;
		if (BallistaRefsComp.Refs.PlayersDuringHydraRegrowHealthSettings == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Player.IsPlayerDead())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(BallistaRefsComp.Refs.PlayersDuringHydraRegrowHealthSettings, this);
		// constrain to platform?
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearSettingsByInstigator(this);
	}
};