class AMagnetDroneCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshBodyComp;

	
	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshArmComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagneticSurfaceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UBoxComponent LaunchArea;

	UPROPERTY(DefaultComponent)
	UArrowComponent ArrowComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UArrowComponent LaunchAngle;

	UPROPERTY(EditAnywhere)
	float Power = 7500;

	UPROPERTY()
	FHazeTimeLike TimeLike;

	float SpringStrength;
	float Bounce;

	float Duration;

	UPROPERTY(EditAnywhere)
	float ConstraintHitDelay = 2;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"OnMagnetDroneAttached");
		TimeLike.BindUpdate(this, n"UpdateSpringStrength");
		// TranslateComp.OnMaxConstraintHit.AddUFunction(this,n"OnMaxHit");
		TranslateComp.OnMinConstraintHit.AddUFunction(this,n"OnMinHit");
		SpringStrength = TranslateComp.SpringStrength;
		Bounce = TranslateComp.ConstrainBounce;
	}

	UFUNCTION()
	private void OnMinHit(float Strength)
	{
		TranslateComp.SpringStrength = 0;
		TranslateComp.ConstrainBounce = 0;
	 	Timer::SetTimer(this, n"UpdateTarget", ConstraintHitDelay, false);
		//TranslateComp.ApplyImpulse(ArrowComp.WorldLocation,ArrowComp.GetForwardVector() * 1);

	}

	// UFUNCTION()
	// private void OnMaxHit(float Strength)
	// {
	// 	TranslateComp.SpringStrength = 0;
	// 	TranslateComp.ConstrainBounce = 0;
	//  	Timer::SetTimer(this, n"UpdateTarget", ConstraintHitDelay, false);
	// 	//TranslateComp.ApplyImpulse(ArrowComp.WorldLocation,ArrowComp.GetForwardVector() * 1);
	// 	MeshBodyComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	// 	MeshArmComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	// }

	UFUNCTION()
	private void UpdateTarget()
	{
		TranslateComp.SpringStrength = SpringStrength;
		TranslateComp.ConstrainBounce = Bounce;
		MeshBodyComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		MeshArmComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	private void UpdateSpringStrength(float Alpha)
	{
	}

	UFUNCTION()
	private void OnMagnetDroneAttached(FOnMagnetDroneAttachedParams Params)
	{
		TranslateComp.ApplyImpulse(Params.Location, Params.Normal * -1000); 
		if(LaunchArea.IsOverlappingActor(Drone::GetSwarmDronePlayer()))
		{
			Drone::GetSwarmDronePlayer().AddMovementImpulse(LaunchAngle.ForwardVector * Power, NAME_None);
			MeshBodyComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			MeshArmComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TranslateComp.SpringStrength = Math::FInterpTo(TranslateComp.SpringStrength, 2, DeltaSeconds, 1);
		Print(""+TranslateComp.SpringStrength,0);
	}

}