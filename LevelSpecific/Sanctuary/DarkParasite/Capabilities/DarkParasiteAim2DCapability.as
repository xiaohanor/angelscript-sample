class UDarkParasiteAim2DCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasite);
	default CapabilityTags.Add(DarkParasite::Tags::DarkParasiteAim);
	
	default DebugCategory = DarkParasite::Tags::DarkParasite;

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 51;

	UDarkParasiteUserComponent UserComp;
	UPlayerAimingComponent AimComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UDarkParasiteUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if (!AimComp.HasAiming2DConstraint())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DarkParasite::bAltControlScheme)
		{
			if (!IsActioning(ActionNames::SecondaryLevelAbility))
				return true;
		}
		else
		{
			if (!IsActioning(ActionNames::SecondaryLevelAbility))
			{
				if (!UserComp.AttachedData.IsValid())
					return true;
			}

			if (WasActionStarted(ActionNames::PrimaryLevelAbility))
				return true;
		}
		
		if (!AimComp.HasAiming2DConstraint())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings AimSettings;
		AimSettings.bShowCrosshair = true;
		AimSettings.OverrideAutoAimTarget = UDarkParasiteTargetComponent;
		AimComp.StartAiming(UserComp, AimSettings);

		Player.BlockCapabilities(DarkProjectile::Tags::DarkProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if (UserComp.GrabbedData.IsValid())
		{
			DarkParasite::TriggerHierarchyRelease(Player, 
				UserComp.AttachedData,
				UserComp.GrabbedData);
		}
	
		if (UserComp.AttachedData.IsValid())
		{
			DarkParasite::TriggerHierarchyDetach(Player, 
				UserComp.AttachedData);
		}

		if (UserComp.FocusedData.IsValid())
		{
			DarkParasite::TriggerHierarchyUnfocus(Player, 
				UserComp.FocusedData);
		}

		UserComp.GrabbedData = FDarkParasiteTargetData();
		UserComp.AttachedData = FDarkParasiteTargetData();
		UserComp.FocusedData = FDarkParasiteTargetData();

		AimComp.StopAiming(UserComp);
		Player.UnblockCapabilities(DarkProjectile::Tags::DarkProjectile, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const auto& PreviousTargetData = UserComp.FocusedData;
		auto TargetData = UserComp.GetAimTargetData();

		if (TargetData.TargetComponent != PreviousTargetData.TargetComponent)
		{
			// Call unfocus response on previous target if any
			if (PreviousTargetData.IsValid())
			{
				DarkParasite::TriggerHierarchyUnfocus(Player,
					PreviousTargetData);
			}
		
			// Call focus response on new target if any
			if (TargetData.IsValid())
			{
				DarkParasite::TriggerHierarchyFocus(Player,
					TargetData);
			}
		}

		UserComp.FocusedData = TargetData;
		Player.Mesh.RequestOverrideFeature(n"DarkParasite", this);
	}
}