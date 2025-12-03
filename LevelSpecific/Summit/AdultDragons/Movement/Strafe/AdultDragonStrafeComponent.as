enum EAdultDragonStormStrafeState
{
	Flying,
	Dash
};

event void BeginOverlapAcidDissolveSphereEvent(AAcidDissolveSphere DissolveSphere);
event void EndOverlapAcidDissolveSphereEvent(AAcidDissolveSphere DissolveSphere);

class UAdultDragonStrafeComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSettingsDataAsset StrafeCameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonSplineFollowRubberBandingSettings DefaultRubberBandSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UAdultDragonStrafeSettings DefaultStrafeSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	TSubclassOf<UCameraShakeBase> DashCameraShake;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	UHazeCameraSpringArmSettingsDataAsset DashCameraSettings;

	TInstigated<EAdultDragonStormStrafeState> AnimationState;

	FVector Velocity;

	FVector2D Input;

	// More animation stuff, by animators for animators
	FHazeAcceleratedFloat AnimAirSmashRoll;

	FRotator InputRotation;

	FHazeAcceleratedQuat AccMovementRotation;

	UPROPERTY()
	BeginOverlapAcidDissolveSphereEvent OnBeginOverlapAcidDissolveSphere;

	UPROPERTY()
	EndOverlapAcidDissolveSphereEvent OnEndOverlapAcidDissolveSphere;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		if (PlayerOwner != nullptr)
		{
			if (DefaultRubberBandSettings != nullptr)
				PlayerOwner.ApplyDefaultSettings(DefaultRubberBandSettings);
			if (DefaultStrafeSettings != nullptr)
				PlayerOwner.ApplyDefaultSettings(DefaultStrafeSettings);
		}
	}
}
