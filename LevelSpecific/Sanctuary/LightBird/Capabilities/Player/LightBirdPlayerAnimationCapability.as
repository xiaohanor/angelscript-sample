class ULightBirdPlayerAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement; // After action movement so we react the same frame as states are changed

	ULightBirdUserComponent UserComp;

	float CooldownTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Time::GameTimeSeconds < CooldownTime)
			return false; // Do not allow spamming activations

		return ShouldRequestFeature(); 
	}

	bool ShouldRequestFeature() const
	{
		if (!Player.Mesh.CanRequestOverrideFeature())
			return false;
		if (UserComp.State == ELightBirdState::Aiming)
			return true;
		if (UserComp.State == ELightBirdState::Lantern)
			return true;
		if (UserComp.Companion == nullptr)
			return false;
		if (UserComp.bIsIlluminating)
		{
			if (IsActioning(ActionNames::SecondaryLevelAbility))
				return true;
			auto CompanionComp = USanctuaryLightBirdCompanionComponent::Get(UserComp.Companion);
			if ((CompanionComp.State != ELightBirdCompanionState::Investigating) && (CompanionComp.State != ELightBirdCompanionState::InvestigatingAttached))
				return true;
		}
		FName CompanionFeature = UBasicAIAnimationComponent::Get(UserComp.Companion).FeatureTag;
		if (CompanionFeature == LightBirdCompanionAnimTags::LaunchExit)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !ShouldRequestFeature();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		CooldownTime = Time::GameTimeSeconds + 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UserComp.AnimationData.bIsAiming = (UserComp.State == ELightBirdState::Aiming);
		Player.Mesh.RequestOverrideFeature(n"LightBird", this);

		if (Player.IsAnyCapabilityActive(n"LightBirdShield"))
			UserComp.AnimationData.AimSpace = FVector2D::ZeroVector;
		else
			UserComp.AnimationData.AimSpace = Player.CalculatePlayerAimAnglesBuffered(UserComp.AnimationData.AimSpace);
	}
};