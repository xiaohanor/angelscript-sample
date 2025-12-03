class ASkylineHitSlingThingSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SpawnPivot;

	UPROPERTY(DefaultComponent, Attach = SpawnPivot)
	USceneComponent SpawnLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent LoaderPivot;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY(EditAnywhere)
	TSubclassOf<ASkylineHitSlingThing> ObjectClass;

	private int SpawnActorIndex;

	float LoaderDistance = 200.0;

	bool bLandingReady = false;

	FHazeAcceleratedFloat BallZ;
	FHazeAcceleratedFloat BallSpin;
	FHazeAcceleratedFloat LoaderZ;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnObject();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		BallSpin.AccelerateTo(0.0, 3.0, DeltaSeconds);
		LoaderZ.SpringTo(0.0, 100.0, 0.4, DeltaSeconds);

		SpawnLocation.AddLocalRotation(FRotator(0.0, BallSpin.Value * DeltaSeconds, 0.0));

		if (!bLandingReady && BallZ.Velocity < 0.0 && BallZ.Value < 50.0)
			bLandingReady = true;

		if (bLandingReady)
			BallZ.SpringTo(0.0, 80.0, 0.6, DeltaSeconds);
		else
			BallZ.ThrustTo(-10000.0, 3000.0, DeltaSeconds);

		float Alpha = (Math::Sin(Time::GameTimeSeconds * 4.0) + 1.0) * 0.5;

		SpawnLocation.RelativeLocation = FVector::UpVector * (BallZ.Value + Alpha * 10.0);
		LoaderPivot.RelativeLocation = FVector::UpVector * LoaderZ.Value;
	}

	UFUNCTION()
	void SpawnObject()
	{
		BallSpin.SnapTo(800.0);
		BallZ.SnapTo(-200.0, 1500.0);
		SpawnLocation.RelativeLocation = FVector::UpVector * BallZ.Value;
		bLandingReady = false;

		auto HitSlingThing = SpawnActor(ObjectClass, SpawnLocation.WorldLocation, SpawnLocation.WorldRotation, bDeferredSpawn = true);
		HitSlingThing.MakeNetworked(this, SpawnActorIndex);
		SpawnActorIndex++;
		HitSlingThing.Spawner = this;
		HitSlingThing.AttachToComponent(SpawnLocation);
		FinishSpawningActor(HitSlingThing);

		HitSlingThing.OnExpire.AddUFunction(this, n"HandleExpire");
		USkylineHitSlingThingSpawnerEventHandler::Trigger_OnSpawn(this);

	}

	UFUNCTION()
	void HandleExpire(ASkylineHitSlingThing HitSlingThing)
	{
		HitSlingThing.OnExpire.Unbind(this, n"HandleExpire");

		LoaderZ.SnapTo(0.0, -2000.0);
		LoaderPivot.RelativeLocation = FVector::UpVector * LoaderZ.Value;

		QueueComp.Idle(0.2);
		QueueComp.Event(this, n"SpawnObject");
	}
};