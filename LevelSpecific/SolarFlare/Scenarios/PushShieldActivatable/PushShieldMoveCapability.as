class UPushShieldMoveCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PushShieldMoveCapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	UPushableShieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UPushableShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).X <= 0.0)
			return false;

		if (IsActioning(ActionNames::PrimaryLevelAbility))
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).X <= 0.0)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.Shield.StartShieldPush(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.Shield.StopShieldPush(Player);
	}
}