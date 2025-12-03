class AMeltdownBossPhaseTwoTridentProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ElectricTrail;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ElectrictBody;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ElectricAmbience;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent ElectricBolt;

	UPROPERTY(DefaultComponent)
	UHazeSphereCollisionComponent Collision;

	UPROPERTY()
	float Speed = 1500;
	UPROPERTY()
	float TurnRate = 20.0;
	UPROPERTY()
	float Lifetime = 5.0;

	AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"CollisionOverlap");
	}

	UFUNCTION()
	private void CollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                              UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                              const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		Player.DamagePlayerHealth(0.5);
	}

	UFUNCTION(BlueprintCallable)
	void StartMoving()
	{
		
	 bLaunched = true;
	 Timer = 0.0;

	 OriginalLaunchDirection = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();
	 ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bLaunched)
			return;

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal().VectorPlaneProject(FVector::UpVector);
				
		if (TargetVector.DotProduct(OriginalLaunchDirection) > 0)
		{
			ActorRotation = Math::RInterpConstantShortestPathTo(
				ActorRotation,
				FRotator::MakeFromX(TargetVector),
				DeltaSeconds,
				TurnRate,
			);
		}

		ActorLocation += ActorForwardVector * Speed * DeltaSeconds;

		Timer += DeltaSeconds;
		if (Timer > Lifetime)
		{
			DestroyActor();
		}
	}
	
};