class ASummitHangingClimbableObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailClimbableComponent ClimbComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsConeRotateComponent ConeRotationComponent;

	UPROPERTY(DefaultComponent, Attach = ConeRotationComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, NotEditable, Attach = Mesh)
	UFauxPhysicsWeightComponent WeightComponent;
	default WeightComponent.bApplyGravity = true;
	default WeightComponent.bApplyInertia = true;

	UPROPERTY(EditAnywhere)
	USummitHangingClimbableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		ClimbComp.OnTailClimbStarted.AddUFunction(this, n"AddLandingImpulse");
		ClimbComp.OnTailClimbStopped.AddUFunction(this, n"AddLeapOffImpulse");
		Settings = USummitHangingClimbableSettings::GetSettings(this);

		WeightComponent.MassScale = Settings.ObjectMassScale;
	}

	UFUNCTION(NotBlueprintCallable)
	void AddLandingImpulse(FTeenDragonTailClimbParams Params)
	{
		FVector LandingLocation = Params.Location;
		FVector Impulse = -Params.ClimbUpVector * Settings.LandingImpulse;
		FauxPhysics::ApplyFauxImpulseToParentsAt(WeightComponent, LandingLocation, Impulse);
	}

	UFUNCTION(NotBlueprintCallable)
	void AddLeapOffImpulse(FTeenDragonTailClimbParams Params)
	{
		FVector LandingLocation = Params.Location;
		FVector Impulse = -Params.ClimbUpVector * Settings.LandingImpulse;
		FauxPhysics::ApplyFauxImpulseToParentsAt(WeightComponent, LandingLocation, Impulse);
	}

}