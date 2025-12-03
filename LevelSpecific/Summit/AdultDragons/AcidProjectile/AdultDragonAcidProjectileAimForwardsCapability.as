class UAdultDragonAcidProjectileAimForwardsCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);	
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonAim);

	default TickGroup = EHazeTickGroup::BeforeGameplay;
	default TickGroupOrder = -110; // Needs to be before 'PlayerAimingUpdateCapability' 

	default DebugCategory = SummitDebugCapabilityTags::AdultDragon;

	UPlayerAimingComponent AimComp;
	UPlayerAcidAdultDragonComponent DragonComp;
	UPlayerTargetablesComponent PlayerTargetables;
	APlayerAdultDragonAimWidget AimWidget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AimComp = UPlayerAimingComponent::Get(Player);
		DragonComp = UPlayerAcidAdultDragonComponent::Get(Player);
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
		//JOHN - experimenting a little with moving the aim slightly down
		UPlayerAimingSettings::SetScreenSpaceAimOffset(Player, FVector2D(FVector2D(0.0, 0.01)), this, EHazeSettingsPriority::Gameplay);


		

		FAimingSettings Settings;
		// Settings.bShowCrosshair = true;
		Settings.bUseAutoAim = true;
		// Settings.bCrosshairFollowsTarget = true;
		// Settings.OverrideCrosshairWidget = DragonComp.AcidShotCrosshair;
		Settings.OverrideAutoAimTarget = UAdultDragonAcidAutoAimComponent;
		AimComp.StartAiming(Player, Settings);
		AimWidget.RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UPlayerAimingSettings::ClearScreenSpaceAimOffset(Player, this);
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

		// Why does the dragon have a AimDirection and origin when the aim component has the aim direction and origin?
		// Now they will not match up since they are updating in different places
		// since they update in different places, Tyko
		DragonComp.AimDirection = AimDirection;
		DragonComp.AimOrigin = AimResult.AimOrigin;

		AimWidget.SetAimDirection(AimResult);
		
		FTargetableOutlineSettings OutlineSettings;
        OutlineSettings.MaximumOutlinesVisible = 1;
        OutlineSettings.TargetableCategory = n"Acid";
        OutlineSettings.bShowVisibleTargets = true;
        PlayerTargetables.ShowOutlinesForTargetables(OutlineSettings);

		// Old temp debug widget
		// {
		// 	FVector CylinderStart = AimResult.AimOrigin + AimResult.AimDirection * 2000;
		// 	FVector CylinderEnd = CylinderStart + AimResult.AimDirection * 10;

		// 	Debug::DrawDebugCylinder(CylinderStart, CylinderEnd, 100, 50, FLinearColor::White, 20);

		// 	CylinderStart = AimResult.AimOrigin  + AimResult.AimDirection * 4000;
		// 	CylinderEnd = CylinderStart + AimResult.AimDirection * 10;

		// 	Debug::DrawDebugCylinder(CylinderStart, CylinderEnd, 100, 50, FLinearColor::White, 20);
			
		// 	if(AimResult.AutoAimTarget != nullptr)
		// 	{
		// 		CylinderStart = AimResult.AutoAimTargetPoint;
		// 		CylinderEnd = CylinderStart - AimResult.AimDirection * 50;
		// 		Debug::DrawDebugCylinder(CylinderStart, CylinderEnd, 750, 200, FLinearColor::Red, 20);
		// 	}
		// }

	}
};