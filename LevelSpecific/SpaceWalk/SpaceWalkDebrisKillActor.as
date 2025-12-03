class ASpaceWalkDebrisKillActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Debris;

	UPROPERTY(DefaultComponent, Attach = Debris)
	UDeathTriggerComponent Kill;

	UPROPERTY()
	float Speed = 2500.0;
	UPROPERTY()
	float TurnRate = 5000.0;
	UPROPERTY()
	float Lifetime = 3.0;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	FVector StartScale = FVector(0.1,0.1,0.1);
	FVector EndScale = FVector (0.5,0.5,0.5);

	FHazeTimeLike AsteroidScale;
	default AsteroidScale.Duration = 1.0;
	default AsteroidScale.UseLinearCurveZeroToOne();

	FRotator RotationSpeed;
	FVector MovementDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AsteroidScale.BindUpdate(this, n"UpdateScale");
	}

	UFUNCTION()
	private void UpdateScale(float CurrentValue)
	{
		Debris.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);
		MovementDirection = ActorForwardVector;

		AsteroidScale.PlayFromStart();
		RotationSpeed = Math::RandomRotator(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bLaunched)
			return;

		if (!TargetPlayer.IsPlayerDead())
			MovementDirection = (TargetPlayer.ActorLocation - ActorLocation).GetSafeNormal();
		SetActorLocationAndRotation(
			ActorLocation + MovementDirection * Speed * DeltaSeconds,
			ActorRotation + RotationSpeed * DeltaSeconds
		);
		
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