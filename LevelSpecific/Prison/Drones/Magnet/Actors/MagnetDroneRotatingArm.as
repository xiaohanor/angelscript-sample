class AMagnetDroneRotatingArm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent MeshComp;

	float Strength = 0;

	bool bMagnetAttached = false;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent MagnetCenter;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 7500;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY()
	FHazeTimeLike TimeLike;

	float SpringStrength;
	float Bounce;

	UPROPERTY(EditAnywhere)
	float ConstraintHitDelay = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");
		RotateComp.OnMaxConstraintHit.AddUFunction(this,n"OnMaxHit");
		SpringStrength = RotateComp.SpringStrength;
		Bounce = RotateComp.ConstrainBounce;

	}

	UFUNCTION()
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		RotateComp.SpringStrength = 0;
		Strength = 750;
		bMagnetAttached = true;			
		
		FVector Force = MagnetCenter.WorldLocation - Drone::GetMagnetDronePlayer().ActorLocation;
			Force.Normalize();
			Force *= Strength;
			RotateComp.ApplyImpulse(Drone::GetMagnetDronePlayer().ActorLocation,Force);
	}

	UFUNCTION()
	private void OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		RotateComp.SpringStrength = SpringStrength;
		Strength = 0;
		RotateComp.SpringStrength = 0;
		bMagnetAttached = false;
	}

	UFUNCTION()
	private void OnMaxHit(float Power)
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bMagnetAttached)
		{
			RotateComp.SpringStrength = 0;
		}
		else
		{
			SpringStrength = Math::FInterpConstantTo(SpringStrength,1,DeltaSeconds,1);
			RotateComp.SpringStrength = SpringStrength;
		}
	}

}