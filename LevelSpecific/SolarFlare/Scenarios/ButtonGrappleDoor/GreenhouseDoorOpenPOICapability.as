class UGreenhouseDoorOpenPOICapability : UHazeCapability
{
	default CapabilityTags.Add(n"GreenhouseDoorOpenPOICapability");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AGreenhouseEntranceDoor Door;

	bool bDeactivate = false;

	float POITime = 2.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Door = Cast<AGreenhouseEntranceDoor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bDeactivate)
			return false;
		if (!Door.bOpenedDoor)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Time::GameTimeSeconds > POITime)
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		POITime += Time::GameTimeSeconds;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ApplyCameraSettings(Door.CameraSettings, 1.0, this, EHazeCameraPriority::High);
			FHazePointOfInterestFocusTargetInfo PoiData;
			PoiData.SetFocusToActor(Door);
			PoiData.WorldOffset = FVector(0.0, 0.0, 150.0);
			FApplyPointOfInterestSettings Settings;
			Settings.InputPauseTime = 1.0;		
			Player.ApplyPointOfInterest(this, PoiData, Settings, 1.0, EHazeCameraPriority::High);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearCameraSettingsByInstigator(this, 1.5);
			Player.ClearPointOfInterestByInstigator(this);
		}

		bDeactivate = true;
	}
}