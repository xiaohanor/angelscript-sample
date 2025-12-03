struct FLightBirdPlayerFireParams
{
	FLightBirdTargetData TargetData;
}

class ULightBirdPlayerFireCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdFire);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;
	float CooldownTime = 0.0; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FLightBirdPlayerFireParams& Params) const
	{
		if (Time::GameTimeSeconds < CooldownTime)
			return false; // Do not allow spamming activations

		if (!AimComp.IsAiming(UserComp))
			return false;

		if (TargetablesComp.TargetingMode.Get() != EPlayerTargetingMode::SideScroller)
		{
			if (!WasActionStopped(ActionNames::PrimaryLevelAbility))
				return false;
		}
		else
		{
			if (!UserComp.AimTargetData.IsValid())
				return false;

			if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
				return false;
		}

		Params.TargetData = UserComp.AimTargetData;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FLightBirdPlayerFireParams Params)
	{
		if (Params.TargetData.IsValid())
		{
			UserComp.Attach(Params.TargetData);
		}
		else
		{
			UserComp.PreviousInvalidTargetData = Params.TargetData;
			UserComp.Hover();
		}
		CooldownTime = Time::GameTimeSeconds + 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}