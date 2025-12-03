asset SkylineGravityZoneCameraSettings of UHazeCameraSpringArmSettingsDataAsset
{
	CameraSettings.bUseFOV = true;
	CameraSettings.FOV = 70.0;

	SpringArmSettings.bUseIdealDistance = true;
	SpringArmSettings.IdealDistance = 900.0;
}

class USkylineGravityZoneComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	UAnimSequence GravitySwitchAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings = SkylineGravityZoneCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	float SwitchDuration = 1.4;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	bool bLimitRetainedVelocity = false;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone", Meta = (EditCondition = "bLimitRetainedVelocity", EditConditionHides))
	float MaxRetainedVelocity = 4000.0;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	float Drag = 1.0;

	UPROPERTY(EditDefaultsOnly, Category = "Gravity Zone")
	float LiftDistance = 200.0;

	ASkylineGravityZone ActiveZone;
	TArray<ASkylineGravityZone> RegisteredZones;

	void RegisterZone(ASkylineGravityZone GravityZone)
	{
		if (GravityZone == nullptr)
			return;

		RegisteredZones.AddUnique(GravityZone);
	}

	void UnregisterZone(ASkylineGravityZone GravityZone)
	{
		if (GravityZone == nullptr)
			return;

		RegisteredZones.Remove(GravityZone);
	}

	ASkylineGravityZone GetPrimaryZone() const property
	{
		if (RegisteredZones.Num() == 0)
			return nullptr;

		return RegisteredZones.Last();
	}
}