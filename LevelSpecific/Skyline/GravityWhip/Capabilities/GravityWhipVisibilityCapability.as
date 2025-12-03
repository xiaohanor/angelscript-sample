class UGravityWhipVisibilityCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityWhipVisibility");
	default CapabilityTags.Add(GravityWhipTags::GravityWhip);

	default TickGroup = EHazeTickGroup::Input;

	UGravityWhipUserComponent WhipComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WhipComp = UGravityWhipUserComponent::Get(Player);
		WhipComp.Whip.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WhipComp.IsWhipSpawned())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WhipComp.IsWhipSpawned())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		WhipComp.Whip.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(WhipComp.Whip != nullptr)
			WhipComp.Whip.AddActorDisable(this);
	}
};