class AMedallionHydraStarProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	TSubclassOf<AMedallionHydra2DProjectile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	bool bActive = true;

	float RotationSpeed = 200.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bActive)
			AddActorDisable(this);
		
		QueueComp.SetLooping(true);
		QueueComp.Idle(0.2);
		QueueComp.Event(this, n"FireProjectile");
	}

	UFUNCTION()
	private void FireProjectile()
	{
		SpawnActor(ProjectileClass, ActorLocation, FRotator::MakeFromXY(ActorRightVector, ActorForwardVector));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AddActorLocalRotation(FRotator(0.0, 0.0, RotationSpeed * DeltaSeconds));
	}
};