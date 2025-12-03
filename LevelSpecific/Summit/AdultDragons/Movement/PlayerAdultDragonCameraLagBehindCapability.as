class UPlayerAdultDragonCameraLagBehindCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragon);
	default CapabilityTags.Add(AdultDragonCapabilityTags::AdultDragonCamera);
	default DebugCategory = n"AdultDragon";

	UPlayerAdultDragonComponent DragonComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DragonComp = UPlayerAdultDragonComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DragonComp.bCameraShouldLagBehind)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DragonComp.bCameraShouldLagBehind)
			return true;

		if(Time::GetGameTimeSeconds() - DragonComp.TimeOfStartCameraLag > DragonComp.CameraLagDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DragonComp.bCameraShouldLagBehind = false;
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FocusPos = Math::Lerp(DragonComp.DragonPosWhenStartCameraLag, Player.ActorLocation, Math::Sin((Time::GetGameTimeSeconds() - DragonComp.TimeOfStartCameraLag) / DragonComp.CameraLagDuration * PI / 2));
		UCameraSettings::GetSettings(Player).IdealDistance.ApplyAsAdditive(FocusPos.Distance(Player.ActorLocation), this);
	}
}