class USkylineSentryBossCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"BossCamera");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	USkylineSentryBossPlayerLandedComponent LandedComp;	
	ASKylineSentryBoss Boss;



	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{	
		if(Boss == nullptr)
			return false;

		if(!Boss.bIsPlayerOnBoss)
			return false;

		// if(Player.ActorCenterLocation.IsWithinDist(Boss.ActorLocation, 1900))
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Boss.bIsPlayerOnBoss)
			return true;

		// if(Player.ActorCenterLocation.IsWithinDist(Boss.ActorLocation, 1750))
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

		Player.ActivateCamera(LandedComp.DefaultCamera, 2.0, this, EHazeCameraPriority::Medium);
		Player.BlockCapabilities(GravityBladeTags::GravityBladeAim, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.DeactivateCameraByInstigator(this, 1.25);

		Player.UnblockCapabilities(GravityBladeTags::GravityBladeAim, this);

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Boss == nullptr)
		{
			LandedComp = USkylineSentryBossPlayerLandedComponent::Get(Owner);
			if(LandedComp != nullptr)
				Boss = Cast<ASKylineSentryBoss>(LandedComp.Boss);

		}
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't apply blend in tick
		// Use manual fraction or manually lerp the value and apply it with 0 blend
		// Tyko
		//float Blend = 0.2;

		int CameraSettingsPrio = 60;

		FHazeCameraClampSettings CameraClampSettings;
		CameraClampSettings.ApplyCameraSpaceCenterOffset(FRotator(-70, 0.0, 0.0));
		CameraClampSettings.ApplyClampsPitch(0, 0);
		UCameraSettings::GetSettings(Player).Clamps.Apply(CameraClampSettings, this, 0, SubPriority = CameraSettingsPrio);

		auto Settings = UCameraSettings::GetSettings(Player);
		Settings.IdealDistance.Apply(2000, this, SubPriority = CameraSettingsPrio);
		Settings.MinDistance.Apply(2000, this, SubPriority = CameraSettingsPrio);
		Settings.PivotOffset.Apply(FVector::ZeroVector, this, SubPriority = CameraSettingsPrio);
		Settings.WorldPivotOffset.Apply(Player.ActorLocation - LandedComp.Boss.ActorLocation, this, SubPriority = CameraSettingsPrio);
		Settings.FOV.Apply(60, this, SubPriority = CameraSettingsPrio);
	}

}