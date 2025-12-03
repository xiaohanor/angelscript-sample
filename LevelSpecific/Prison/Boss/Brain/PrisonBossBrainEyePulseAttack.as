event void FPrisonBossBrainEyePulseAttackDestroyedEvent(APrisonBossBrainEyePulseAttack Attack);

UCLASS(Abstract)
class APrisonBossBrainEyePulseAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PulseRoot;

	UPROPERTY(DefaultComponent, Attach = PulseRoot)
	USceneComponent OscillationRoot;

	UPROPERTY(DefaultComponent, Attach = OscillationRoot)
	USceneComponent CircleRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	FPrisonBossBrainEyePulseAttackDestroyedEvent OnAttackDestroyed;

	float LifeTime = 0.0;

	bool bDestroyed = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PulseRoot.SetRelativeScale3D(FVector::ZeroVector);

		UPrisonBossBrainEyePulseAttackEffectEventHandler::Trigger_Spawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bDestroyed)
			return;

		float Scale = Math::FInterpConstantTo(PulseRoot.RelativeScale3D.X, 1.0, DeltaTime, 2.0);
		PulseRoot.SetRelativeScale3D(FVector(Scale));

		AddActorWorldOffset(ActorForwardVector * PrisonBoss::PulseAttackProjectileSpeed * DeltaTime);

		LifeTime += DeltaTime;
		if (LifeTime >= PrisonBoss::PulseAttackLifeTime)
			Destroy();

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseSphereShape(60.0);

		FHitResult Hit = Trace.QueryTraceSingle(CircleRoot.WorldLocation, CircleRoot.WorldLocation + (FVector(0.0, 0.0, 0.1)));
		if (Hit.bBlockingHit)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if (Player != nullptr)
				Player.DamagePlayerHealth(PrisonBoss::PulseAttackDamage, FPlayerDeathDamageParams(ActorForwardVector), DamageEffect, DeathEffect);

			Destroy();
		}

		OscillationRoot.AddLocalRotation(FRotator(0.0, 240.0 * DeltaTime, 0.0));
	}

	void Destroy()
	{
		if (bDestroyed)
			return;

		bDestroyed = true;
		OnAttackDestroyed.Broadcast(this);
		BP_Destroy();

		SetActorHiddenInGame(true);

		UPrisonBossBrainEyePulseAttackEffectEventHandler::Trigger_Destroy(this);

		Timer::SetTimer(this, n"ActuallyDestroy", 2.0);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}

	UFUNCTION()
	private void ActuallyDestroy()
	{
		DestroyActor();
	}
}