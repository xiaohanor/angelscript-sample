event void FOnForceFieldEmitterDestroy();


class ASkylineSentryBossForceFieldEmitter : AHazeActor
{
	FOnForceFieldEmitterDestroy OnEmitterDestroy;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RayRoot;

	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineSentryBossPulse> PulseClass;

	int HitPoints = 3;

	float PulseCooldown = 2.5;
	float TimeToPulse;

	float InitialPulseSpeed = 50;
	float PulseAcceleration = 50;

	float MaxTravelDistance = 700;
	float Radius = 2400;

	bool bActive;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"OnHit");
	}
	

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bActive)
			return;

		if(TimeToPulse > Time::GameTimeSeconds)
			return;

		TimeToPulse = Time::GameTimeSeconds + PulseCooldown;

		auto Pulse = SpawnActor(PulseClass, bDeferredSpawn = true);
		Pulse.PulseScaleComponent.Radius = Radius;
		Pulse.PulseScaleComponent.Origin = AttachmentRootActor;
		Pulse.MaxTravelDistance = MaxTravelDistance;
		Pulse.Speed = InitialPulseSpeed;
		Pulse.Acceleration = InitialPulseSpeed;


		FTransform SpawnTransform;
		SpawnTransform.Location = AttachmentRootActor.ActorLocation + (ActorLocation - AttachmentRootActor.ActorLocation).SafeNormal * Pulse.PulseScaleComponent.Radius;
		FinishSpawningActor(Pulse, SpawnTransform);
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		HitPoints--;

		if(HitPoints <= 0)
			DestroyActor();

	}

	void Activate()
	{
		TimeToPulse = Time::GameTimeSeconds + PulseCooldown;
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		OnEmitterDestroy.Broadcast();
	}

}