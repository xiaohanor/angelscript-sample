class AMeltdownBossFlyingExplodingAOE : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent ExplodingMesh;

	UPROPERTY(DefaultComponent, Attach = ExplodingMesh)
	UStaticMeshComponent SphereMesh;
	default SphereMesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = ExplodingMesh)
	UHazeSphereCollisionComponent Collision;

	UPROPERTY()
	float Speed = 1000.0;
	UPROPERTY()
	float TurnRate = 5.0;
	UPROPERTY()
	float Lifetime = 10.0;

	UPROPERTY()
	float ExplosionDelay;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collision.OnComponentBeginOverlap.AddUFunction(this,n"OnCollisionOverlap");
		AddActorDisable(this);
	}

	UFUNCTION()
	private void OnCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                                const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;
		
		Timer::SetTimer(this, n"Explode", ExplosionDelay);
		ExplosionTimer();
		Lifetime = 999;
		SetActorTickEnabled(false);

	}

	UFUNCTION(BlueprintEvent)
	void ExplosionTimer()
	{

	}

	UFUNCTION(BlueprintEvent)
	private void Explode()
	{
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);

		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		FVector TargetVector = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();
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
			if (bDestroyOnExpire)
				DestroyActor();
			else
				AddActorDisable(this);
		}
	}

};