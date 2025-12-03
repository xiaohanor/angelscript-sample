class USanctuaryLightBirdShieldIlluminateCapability : UHazePlayerCapability
{
//	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"LightBirdShield");

	default TickGroup = EHazeTickGroup::Gameplay;

	USanctuaryLightBirdShieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = USanctuaryLightBirdShieldUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.bIsActive)
			return false;

//		if (!IsActioning(ActionNames::SecondaryLevelAbility))
//			return false;

		if (!IsValid(UserComp.LightBirdShield))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!UserComp.bIsActive)
			return true;

//		if (!IsActioning(ActionNames::SecondaryLevelAbility))
//			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.LightBirdShield.Illuminate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.LightBirdShield.Unilluminate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
};