class ASolarFlareSlideWalkway : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UPlayerInheritMovementComponent InheritMovement;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SolarFlareSlideWalkwayCapability");

	UPROPERTY(EditAnywhere)
	APlayerForceSlideVolume SlideVolume;

	UPROPERTY(EditAnywhere)
	AHazeCameraVolume CameraVolume;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeStart;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeFinish;

	UPROPERTY()
	float DegreesTarget = -20.0;

	bool bActivated;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SlideVolume.AddActorDisable(this);
		CameraVolume.AddActorDisable(this);
	}

	UFUNCTION()
	void ActivateBreak()
	{
		Timer::SetTimer(this, n"DelaySlideActivate", 0.25);
		CameraVolume.RemoveActorDisable(this);
		bActivated = true;
	}

	UFUNCTION()
	void DelaySlideActivate()
	{
		SlideVolume.RemoveActorDisable(this);
	}
}