class UDentistToothOutlineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Outline);

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UDentistToothPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = UDentistToothPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Outline::AddToPlayerOutlineActor(PlayerComp.GetToothActor(), Player, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Outline::RemoveFromPlayerOutlineActor(PlayerComp.GetToothActor(), Player, this);
	}
};