class ADentistBossFloodLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent FloodLightRoot;

	UPROPERTY(DefaultComponent, Attach = FloodLightRoot)
	USpotLightComponent SpotLightComp;

	UPROPERTY()
	UHazeSphereComponent HazeSphereCompBackDrop;

	UPROPERTY()
	FHazeTimeLike RotateLightTimeLike;
	default RotateLightTimeLike.UseSmoothCurveZeroToOne();
	default RotateLightTimeLike.Duration = 1.0;

	FTransform StartTransform;

	bool bEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartTransform = FloodLightRoot.RelativeTransform;
		RotateLightTimeLike.BindUpdate(this, n"RotateLightTimeLikeUpdate");
		Timer::SetTimer(this, n"Activate", 2.0);
	}

	UFUNCTION()
	void Activate()
	{
		if (bEnabled)
			return;

		RotateLightTimeLike.Play();
		bEnabled = true;
		UDentistBossFloodLightEventHandler::Trigger_OnFloodLightActivated(this);
	}

	UFUNCTION()
	void StartEnabled()
	{
		bEnabled = true;
		FloodLightRoot.SetRelativeLocationAndRotation(ArrowComp.RelativeLocation, ArrowComp.RelativeRotation);
	}

	UFUNCTION()
	private void RotateLightTimeLikeUpdate(float CurrentValue)
	{
		FVector Location = Math::Lerp(StartTransform.Location, ArrowComp.RelativeLocation, CurrentValue);
		FRotator Rotation = Math::LerpShortestPath(StartTransform.Rotation.Rotator(), ArrowComp.RelativeRotation, CurrentValue);
		FloodLightRoot.SetRelativeLocationAndRotation(Location, Rotation);
	}
};