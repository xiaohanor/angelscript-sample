class ASanctuaryHydraSplineRunSpamProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDamageTriggerComponent DamageTriggerComp;

	float Speed = 8000.0;

	float DamageRadius = 200.0;

	float Spread = 2.0;

	float KillZ = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorWorldRotation(Math::GetRandomRotation() * (Spread / 360.0));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DeltaMove = ActorForwardVector * Speed * DeltaSeconds;

		auto Trace = Trace::InitProfile(n"PlayerCharacter");
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		AddActorWorldOffset(DeltaMove);

		if (HitResult.bBlockingHit)
			Explode();

		if (ActorLocation.Z < KillZ)
			Splash();

		if (GameTimeSinceCreation > 10.0)
			DestroyActor();
	}

	UFUNCTION()
	private void Explode()
	{
		for (auto Player : Game::Players)
		{
			if (GetDistanceTo(Player) < DamageRadius)
				Player.DamagePlayerHealth(0.4);
		}

		BP_Explode();
		DestroyActor();
	}

	UFUNCTION()
	private void Splash()
	{
		BP_Splash();
		DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	private void BP_Explode(){}

	UFUNCTION(BlueprintEvent)
	private void BP_Splash(){}
};