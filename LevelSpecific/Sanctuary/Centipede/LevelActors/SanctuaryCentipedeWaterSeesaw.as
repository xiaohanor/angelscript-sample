class ASanctuaryCentipedeWaterSeesaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UCentipedeProjectileResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxPhysicsRotateComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsRotateComp)
	USceneComponent ConstantForceLocationComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsRotateComp)
	USceneComponent WaterForceLocationComp;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsRotateComp)
	UHazeSphereCollisionComponent TriggerComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SeesawWeightPivot;

	UPROPERTY(DefaultComponent, Attach = SeesawWeightPivot)
	USceneComponent WaterMeshScaleComp;

	UPROPERTY(DefaultComponent, Attach = WaterMeshScaleComp)
	UStaticMeshComponent WaterMeshComp;

	float WaterAlpha = 0.0;

	bool bWaterOverlapping = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnWaterBeginOverlap.AddUFunction(this, n"HandleWaterBeginOverlap");
		ResponseComp.OnWaterEndOverlap.AddUFunction(this, n"HandleWaterEndOverlap");
	}

	UFUNCTION()
	private void HandleWaterBeginOverlap(UActorComponent OverlappedComponent)
	{
		bWaterOverlapping = true;
	}

	UFUNCTION()
	private void HandleWaterEndOverlap(UActorComponent OverlappedComponent)
	{
		bWaterOverlapping = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bWaterOverlapping && WaterAlpha < 1.0)
		{
			WaterAlpha += DeltaSeconds * 0.2;
		}

		PrintToScreen("" + WaterAlpha);

		FauxPhysicsRotateComp.ApplyForce(ConstantForceLocationComp.WorldLocation, FVector::DownVector * 1000.0);
		FauxPhysicsRotateComp.ApplyForce(WaterForceLocationComp.WorldLocation, FVector::DownVector * WaterAlpha * 1500.0);
		WaterMeshComp.SetRelativeScale3D(FVector(1.0, 1.0, WaterAlpha));

		SeesawWeightPivot.WorldLocation = WaterForceLocationComp.WorldLocation;
	}
};