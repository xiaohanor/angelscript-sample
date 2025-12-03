class UPlayerPigRainbowFartComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "MoveSettings")
	UMovementGravitySettings GravitySettings;

	UPROPERTY(Category = "MoveSettings")
	UPlayerAirMotionSettings AirMotionSettings;

	UPROPERTY(Category = "Camera")
	TSubclassOf<UCameraShakeBase> CameraShakeClass;

	UPROPERTY(Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset SpringArmSettings;

	UPROPERTY(Category = "Camera")
	FHazeCameraImpulse CameraImpulse;


	access FartCapability = private, UPigRainbowFartCapability;
	access : FartCapability bool bFarting = false;
	access : FartCapability bool bFartInterrupted = false;

	private bool bGroundedAfterFart = true;
	private UPlayerMovementComponent MovementComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovementComponent = UPlayerMovementComponent::Get(Owner);
	}

	void Activate()
	{
		bGroundedAfterFart = false;
		SetComponentTickEnabled(true);
	}

	void Deactivate()
	{
		SetComponentTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Reset state and deactivate after pig hits ground
		if (MovementComponent.IsOnAnyGround())
		{
			ResetCanFart();
		}
	}

	void ResetCanFart()
	{
		bGroundedAfterFart = true;
		Deactivate();
	}

	UFUNCTION()
	void InterruptFart()
	{
		bFartInterrupted = true; 
	}

	bool CanFart() const
	{
		return bGroundedAfterFart;
	}

	UFUNCTION()
	bool IsFarting() const
	{
		return bFarting;
	}
}