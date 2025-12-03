class UGravityBladeVisibilityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BlockedByCutscene");
	default CapabilityTags.Add(GravityBladeTags::GravityBlade);

	default TickGroup = EHazeTickGroup::Input;

	UGravityBladeUserComponent BladeComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BladeComp = UGravityBladeUserComponent::Get(Player);
		BladeComp.Blade.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BladeComp.IsBladeSpawned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BladeComp.IsBladeSpawned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BladeComp.Blade.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(BladeComp.Blade != nullptr)
			BladeComp.Blade.AddActorDisable(this);
	}
};