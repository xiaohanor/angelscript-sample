class AGoatDevourablePhysicsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = CollisionComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UGoatDevourResponseComponent DevourResponseComp;
	default DevourResponseComp.bScaleActor = false;

	FVector LaunchDir;

	float ScaleSpeed = 50.0;
	float DefaultScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DevourResponseComp.OnDevoured.AddUFunction(this, n"Devoured");
		DevourResponseComp.OnSpit.AddUFunction(this, n"SpitOut");
	}

	UFUNCTION()
	private void Devoured()
	{
		ScaleSpeed = MeshComp.RelativeScale3D.X * 4.0;
		DefaultScale = MeshComp.RelativeScale3D.X;
		MeshComp.SetSimulatePhysics(false);
	}

	UFUNCTION()
	private void SpitOut(FGoatDevourSpitParams Params)
	{
		AddActorWorldOffset((FVector::UpVector * DefaultScale * 75.0) + (Params.Direction * DefaultScale * 50.0));

		LaunchDir = Params.Direction;
		Timer::SetTimer(this, n"EnablePhysics", 0.05);
	}

	UFUNCTION()
	void EnablePhysics()
	{
		SetActorEnableCollision(true);
		CollisionComp.SetSimulatePhysics(true);
		FVector Force = (LaunchDir * 1000000.0 + (FVector::UpVector * 80000.0)) * DefaultScale;
		CollisionComp.AddImpulse(Force);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (DevourResponseComp.bTravellingToMouth)
		{
			float Scale = Math::FInterpConstantTo(MeshComp.RelativeScale3D.X, 0.0, DeltaTime, ScaleSpeed);
			MeshComp.SetRelativeScale3D(FVector(Scale));
		}

		if (DevourResponseComp.bSpitOut)
		{
			float Scale = Math::FInterpConstantTo(MeshComp.RelativeScale3D.X, DefaultScale, DeltaTime, ScaleSpeed);
			MeshComp.SetRelativeScale3D(FVector(Scale));
		}
	}
}