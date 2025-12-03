class UAdultDragonTailSmashAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 0; // Needs to be before 'PlayerAimingUpdateCapability' 

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerTailAdultDragonComponent DragonComp;
	UPlayerTargetablesComponent PlayerTargetables;
	APlayerAdultDragonAimWidget AimWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerTailAdultDragonComponent::Get(Player);
		PlayerTargetables = UPlayerTargetablesComponent::Get(Owner);
		
		AimWidget = SpawnActor(DragonComp.AimWidgetClass);
		AimWidget.AttachToComponent(DragonComp.GetDragonMesh());
		AimWidget.AddActorDisable(this);
		AimWidget.SetPlayerOwner(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DragonComp.WantsAiming())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DragonComp.WantsAiming())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FAimingSettings Settings;
		Settings.OverrideAutoAimTarget = UAdultDragonHomingTailSmashAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
		AimWidget.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
		AimComp.StopAiming(Player);
		AimWidget.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FAimingRay OverrideAimRay;
		FVector JawLocation = DragonComp.DragonMesh.GetSocketLocation(n"Jaw");
		OverrideAimRay.Origin = JawLocation;
		OverrideAimRay.Direction = Player.ActorForwardVector;
		AimComp.ApplyAimingRayOverride(OverrideAimRay, this);
		AimComp.UpdateAiming(); // force the update so that the 'GetAimingTarget' gives the correct values

		auto AimResult = AimComp.GetAimingTarget(Player);
		FVector AimDirection = AimResult.AimDirection;

		DragonComp.AimDirection = AimDirection;
		DragonComp.AimOrigin = AimResult.AimOrigin;

		AimWidget.SetAimDirection(AimResult);

		FTargetableOutlineSettings OutlineSettings;
        OutlineSettings.MaximumOutlinesVisible = 1;
        OutlineSettings.TargetableCategory = n"Smash";
        OutlineSettings.bShowVisibleTargets = true;
        PlayerTargetables.ShowOutlinesForTargetables(OutlineSettings);
	}
};