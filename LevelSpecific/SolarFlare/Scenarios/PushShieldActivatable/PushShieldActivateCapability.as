class UPushShieldActivateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"PushShieldActivateCapability");
	
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
		if (!IsActioning(ActionNames::PrimaryLevelAbility))
			return false;
		
		if (GetAttributeVector2D(AttributeVectorNames::MovementRaw).X > 0.0)
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
		UserComp.Shield.StartShieldActivation(Player);
		UserComp.Shield.PlayActivate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.Shield.StopShieldActivation(Player);
		UserComp.Shield.PlayIdle(Player);
	}
}