class AMagnetDroneCatapultbase : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	float SpringStrength;
	float Bounce;

	UPROPERTY(EditAnywhere)
	float ConstraintHitDelay = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		SpringStrength = RotateComp.SpringStrength;
		Bounce = RotateComp.ConstrainBounce;

	}

	UFUNCTION()
	private void UpdateTarget()
	{
		RotateComp.SpringStrength = SpringStrength;
		RotateComp.ConstrainBounce = Bounce;
	}

	UFUNCTION()
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		RotateComp.ApplyImpulse(Params.Player.GetActorLocation(), Params.Normal * -10);
	}
}