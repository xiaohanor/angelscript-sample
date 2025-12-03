class AMagnetDronePushableBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MagneticPlaneComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent, Attach = MagneticPlaneComp)
	UMagnetDroneAutoAimComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;

	float SpringStrength = 1;
	float Bounce;

	bool bConstrainHit = false;

	UPROPERTY(EditAnywhere)
	float ConstraintHitDelay = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		MagneticSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"OnMagnetDroneDetached");
		TranslateComp.OnConstraintHit.AddUFunction(this,n"OnMaxHit");
		SpringStrength = TranslateComp.SpringStrength;
		Bounce = TranslateComp.ConstrainBounce;
	}



	UFUNCTION()
	private void OnMaxHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisX_Max)
		{
			TranslateComp.SpringStrength = 0;
			TranslateComp.ConstrainBounce = 0;
			Timer::SetTimer(this, n"StartMovingBack", ConstraintHitDelay, false,0,0);
		}
		bConstrainHit = true;
	}

	UFUNCTION()
	private void StartMovingBack()
	{
		TranslateComp.SpringStrength = SpringStrength;
		TranslateComp.ConstrainBounce = Bounce;
		TranslateComp.ApplyImpulse(ArrowComp.WorldLocation,ArrowComp.GetForwardVector() * 1);
	}

	UFUNCTION()
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		TranslateComp.ApplyImpulse(ArrowComp.WorldLocation,ArrowComp.GetForwardVector() * 1000);
	}

	UFUNCTION()
	private void OnMagnetDroneDetached(FOnMagnetDroneDetachedParams Params)
	{
		Timer::SetTimer(this, n"StartMovingBack", 0.2f, false,0,0);

	}
}