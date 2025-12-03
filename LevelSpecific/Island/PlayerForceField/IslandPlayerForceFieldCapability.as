class UIslandPlayerForceFieldCapability : UHazePlayerCapability
{
	// LastDemotable since it should run after animtions have run so force field pose matches the player's final pose for the frame
	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 90;

	UIslandForceFieldComponent ForceField;
	UPlayerHealthComponent HealthComp;
	UIslandPlayerForceFieldUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ForceField = UIslandForceFieldComponent::Get(Player);
		ForceField.AttachToComponent(Player.MeshOffsetComponent);
		HealthComp = UPlayerHealthComponent::Get(Player);
		UserComp = UIslandPlayerForceFieldUserComponent::Get(Player);

		if(Player.IsMio())
			ForceField.CurrentType = EIslandForceFieldType::Red;
		else
			ForceField.CurrentType = EIslandForceFieldType::Blue;

		ForceField.InitializeVisuals(Player.Mesh);

		if(Player.IsMio())
		{
			ForceField.Color = UserComp.RedColor;
			ForceField.FillColor = UserComp.RedFillColor;
		}
		else
		{
			ForceField.Color = UserComp.BlueColor;
			ForceField.FillColor = UserComp.BlueFillColor;
		}

		ForceField.MaterialInstance.SetVectorParameterValue(n"Color", ForceField.Color);
		ForceField.MaterialInstance.SetVectorParameterValue(n"FillColor", ForceField.FillColor);

		ForceField.Reset();
		ForceField.AddComponentVisualsBlocker(UserComp);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		if(UserComp.bForceFieldIsDestroyed)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		if(UserComp.bForceFieldIsDestroyed)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		HealthComp.AddDamageInvulnerability(this, MAX_flt);
		UserComp.bForceFieldActive = true;
		Player.BlockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		HealthComp.RemoveDamageInvulnerability(this);
		UserComp.bForceFieldActive = false;
		Player.UnblockCapabilities(IslandRedBlueWeapon::IslandRedBlueWeapon, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ForceField.CopyPoseFromSkeletalComponent(Player.Mesh);
		ForceField.UpdateVisuals(DeltaTime);
	}
}