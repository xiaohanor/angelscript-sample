class ATeenDragonSwings : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseMeshRoot;
	
	UPROPERTY(DefaultComponent, Attach = BaseMeshRoot)
	UFauxPhysicsAxisRotateComponent AxisComponent;
	default AxisComponent.Friction = 0.3;
	default AxisComponent.SpringStrength = 1.8;

	UPROPERTY(DefaultComponent, Attach = AxisComponent)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = AxisComponent)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UPlayerInheritMovementComponent InheritMoveComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent RollHitMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UBoxComponent ApplyCameraSettingsBoxComp;

	UPROPERTY(DefaultComponent, Attach = RollHitMesh)
	UTeenDragonTailAttackResponseComponent ResponseComp;
	default ResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	float MaxForce = 140.0;
	float CameraBlendTime = 3.0;

	FRotator StartingWorldRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
		ApplyCameraSettingsBoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		ApplyCameraSettingsBoxComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		StartingWorldRotation = PlatformRoot.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PlatformRoot.WorldRotation = StartingWorldRotation;
	}

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		AxisComponent.ApplyImpulse(RollHitMesh.WorldLocation, ActorForwardVector * MaxForce);
	}
	
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		Player.ApplyCameraSettings(CameraSettings, CameraBlendTime, this, EHazeCameraPriority::High);
	}
	
	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
			return;

		Player.ClearCameraSettingsByInstigator(this, CameraBlendTime);
	}
};