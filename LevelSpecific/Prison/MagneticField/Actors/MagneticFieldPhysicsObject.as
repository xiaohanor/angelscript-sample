class AMagneticFieldPhysicsObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent PhysicsMesh;
	default PhysicsMesh.SimulatePhysics = true;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent ResponseComp;

	UPROPERTY(EditAnywhere)
	float BurstImpulse = 75000.0;

	UPROPERTY(EditAnywhere)
	float PushForce = 75000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnBurst.AddUFunction(this, n"Burst");
		ResponseComp.OnPush.AddUFunction(this, n"Push");
	}

	UFUNCTION(NotBlueprintCallable)
	private void Burst(const FMagneticFieldData& Data) const
	{
		FVector Impulse;
		FVector Point;
		if(Data.GetForceAndPointForComponent(PhysicsMesh, Impulse, Point))
		{
			Impulse *= BurstImpulse;
			PhysicsMesh.AddImpulseAtLocation(Impulse, Point);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Push(const FMagneticFieldData& Data) const
	{
		FVector Force;
		FVector Point;
		if(Data.GetForceAndPointForComponent(PhysicsMesh, Force, Point))
		{
			Force *= PushForce;
			PhysicsMesh.AddImpulseAtLocation(Force, Point);
		}
	}
}