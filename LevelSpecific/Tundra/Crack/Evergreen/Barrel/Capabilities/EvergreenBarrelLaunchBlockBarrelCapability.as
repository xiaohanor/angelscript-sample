class UEvergreenBarrelLaunchBlockBarrelCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::InfluenceMovement;
	default TickGroupOrder = 2;

	UEvergreenBarrelPlayerComponent BarrelPlayerComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BarrelPlayerComp = UEvergreenBarrelPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BarrelPlayerComp.BarrelToBlock == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BarrelPlayerComp.BarrelToBlock == nullptr)
			return true;

		if(!BarrelPlayerComp.BarrelToBlock.IsPlayerWithinBounds() && !BarrelPlayerComp.BarrelToBlock.ShouldPlayerGetKilled())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		MoveComp.AddMovementIgnoresActor(this, BarrelPlayerComp.BarrelToBlock);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BarrelPlayerComp.BarrelToBlock = nullptr;
		MoveComp.RemoveMovementIgnoresActor(this);
	}
}