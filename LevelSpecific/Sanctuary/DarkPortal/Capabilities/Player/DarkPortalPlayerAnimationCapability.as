class UDarkPortalPlayerAnimationCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Movement; // After action movement so we react the same frame as states are changed

	UDarkPortalUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkPortalUserComponent::Get(Player);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return ShouldRequestFeature(); 
	}

	bool ShouldRequestFeature() const
	{
		if (!Player.Mesh.CanRequestOverrideFeature())
			return false;
		if (UserComp.Portal.IsGrabbingActive())
			return true;
		if (AimComp.IsAiming())
			return true;
		if (UserComp.Portal.State == EDarkPortalState::Launch)
			return true;
		if (UserComp.Portal.State == EDarkPortalState::Recall)
			return true;
		if (UserComp.Portal.bPlayerWantsGrab)
			return true;
		if (UserComp.Companion == nullptr)
			return false;
		FName CompanionFeature = UBasicAIAnimationComponent::Get(UserComp.Companion).FeatureTag;
		if (CompanionFeature == DarkPortalCompanionAnimTags::PortalExit)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !ShouldRequestFeature();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UserComp.AnimationData.bIsAiming = AimComp.IsAiming();
		UserComp.AnimationData.AimSpace = Player.CalculatePlayerAimAnglesBuffered(UserComp.AnimationData.AimSpace);
		if (Player.Mesh.CanRequestOverrideFeature())
			Player.Mesh.RequestOverrideFeature(n"DarkPortal", this);
	}
};