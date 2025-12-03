class AMeltdownBossPhaseThreeHomingProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UDeathTriggerComponent DeathTrigger;
	default DeathTrigger.Shape = FHazeShapeSettings::MakeSphere(50.0);

	UPROPERTY()
	float Speed = 2500.0;
	UPROPERTY()
	float TurnRate = 50.0;
	UPROPERTY()
	float Lifetime = 10.0;

	// Whether to destroy the actor or disable it when it expires
	UPROPERTY()
	bool bDestroyOnExpire = true;

	private AHazePlayerCharacter TargetPlayer;
	private bool bLaunched = false;
	private float Timer = 0.0;
	private FVector OriginalLaunchDirection;

	UFUNCTION(DevFunction)
	void Launch(AHazePlayerCharacter Target)
	{
		bLaunched = true;
		TargetPlayer = Target;
		Timer = 0.0;

		OriginalLaunchDirection = (Target.ActorLocation - ActorLocation).GetSafeNormal();
		ActorRotation = FRotator::MakeFromX(OriginalLaunchDirection);
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