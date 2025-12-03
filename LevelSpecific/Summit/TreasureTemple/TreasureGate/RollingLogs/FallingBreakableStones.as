class AFallingBreakableStones : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent OverlapComp;
	default OverlapComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

	TArray<UStaticMeshComponent> MeshComps;

	bool bBroken;

	float LifeTime = 4.0;

	float CurrentScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetComponentsByClass(MeshComps);
		OverlapComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			CurrentScale = Mesh.GetRelativeScale3D().X;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("NOT BROKEN");
		
		if (!bBroken)
			ActorLocation -= FVector(0.0, 0.0, 4000.0) * DeltaSeconds;
		else
		{
			LifeTime -= DeltaSeconds;
			CurrentScale -= DeltaSeconds * 0.5;

			for (UStaticMeshComponent Mesh : MeshComps)
			{
				Mesh.SetRelativeScale3D(FVector(CurrentScale));
			}

			if (LifeTime <= 0.0)
				DestroyActor();
		}
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bBroken)
			return;

		bBroken = true;
		for (UStaticMeshComponent Mesh : MeshComps)
		{
			FVector Direction = (Mesh.WorldLocation - ActorLocation).GetSafeNormal();
			Mesh.SetSimulatePhysics(true);
			Mesh.AddImpulse(Direction * 25000);
		}
	}
}