class AMetalMorpherAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikesRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SpikesActiveTargetLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitKillAreaSphereComponent DeathSphere;

	FVector StartLocation;
	FVector TelegraphLocation;

	float TelegraphTime;
	float TelegraphDuration = 1.2;
	float SpikeActiveTime;
	float SpikeActiveDuration = 2.5;
	float ActivateSpikeTime;
	float FollowDuration = 4.0;

	float MoveSpeed = 800.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeathSphere.DisableKill();
		StartLocation = SpikesRoot.RelativeLocation;
		TelegraphLocation = StartLocation + FVector(0.0, 0.0, 120.0);

		ActivateSpikeTime = Time::GameTimeSeconds + FollowDuration;

		SetActorTickEnabled(false);

		Timer::SetTimer(this, n"ActivateSpikes", 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > TelegraphTime)
		{
			SpikesRoot.RelativeLocation = Math::VInterpConstantTo(SpikesRoot.RelativeLocation, SpikesActiveTargetLocation.RelativeLocation, DeltaSeconds, 1800.0);
			if (!DeathSphere.CanKillPlayer())
				DeathSphere.EnableKill();
		}
		else	
		{
			SpikesRoot.RelativeLocation = Math::VInterpConstantTo(SpikesRoot.RelativeLocation, TelegraphLocation, DeltaSeconds, 80.0);
		}

		if (Time::GameTimeSeconds > SpikeActiveTime)
		{
			if (DeathSphere.CanKillPlayer())
				DeathSphere.DisableKill();

			DestroyActor();
		}
	}

	UFUNCTION()
	void ActivateSpikes()
	{
		TelegraphTime = Time::GameTimeSeconds + TelegraphDuration;
		SpikeActiveTime = Time::GameTimeSeconds + SpikeActiveDuration;
		SetActorTickEnabled(true);
	}
}