enum EDragonGapFlyingCameraSettingsType
{
	Light,
	Medium,
	Heavy,
	Debris
}

struct FDragonGapFlyingData
{
	UPROPERTY(EditAnywhere)
	TPerPlayer<float> RollAmount;

	UPROPERTY(EditAnywhere)
	bool bAllowSideFlying = true;

	UPROPERTY(EditAnywhere)
	bool bBlockCrosshair = false;

	UPROPERTY(EditAnywhere)
	EDragonGapFlyingCameraSettingsType CameraSettingsType;

	UPROPERTY(EditAnywhere)
	float CameraSettingsBlendTime;

	UPROPERTY(EditAnywhere)
	bool bUseGapFlyMovement = false;

	UPROPERTY(EditAnywhere)
	bool bGapFlyMovementMoveToSpline = true;

	UPROPERTY(EditAnywhere)
	float MioRotationDuration = 1.0;

	UPROPERTY(EditAnywhere)
	float ZoeRotationDuration = 1.0;
}

class AAdultDragonGapFlyingVolume : APlayerTrigger
{
	UPROPERTY(EditAnywhere)
	FDragonGapFlyingData GapFlyingData;

	UPROPERTY(EditAnywhere)
	UHazeCameraSpringArmSettingsDataAsset OverrideCameraSettings;

	UPROPERTY(EditAnywhere)
	bool bBlockTakeDamage = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UPlayerAdultDragonComponent DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DragonComp.SetGapFlying(true, GapFlyingData, OverrideCameraSettings);
		DragonComp.bCanInputRotate = false;

		if (bBlockTakeDamage)
			Player.BlockCapabilities(n"AdultDragonTakeDamageCapability", this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UPlayerAdultDragonComponent DragonComp = UPlayerAdultDragonComponent::Get(Player);
		DragonComp.SetGapFlying(false, GapFlyingData);
		DragonComp.bCanInputRotate = true;

		if (bBlockTakeDamage)
			Player.UnblockCapabilities(n"AdultDragonTakeDamageCapability", this);
	}
};