class ACrystalSiegerMortar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MortarRoot;

	UPROPERTY(DefaultComponent, Attach = MortarRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = MortarRoot)
	UNiagaraComponent Trail;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDecalComponent DecalComp;

	UPROPERTY()
	UNiagaraSystem ImpactSystem;

	AActor Initiator;

	FVector Target;
	FVector Velocity;
	float Gravity = 1400.0;
	float Speed = 400.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Velocity = Trajectory::CalculateVelocityForPathWithHorizontalSpeed(ActorLocation, Target, Gravity, Speed);
		DecalComp.SetWorldLocation(Target);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MortarRoot.WorldLocation += Velocity * DeltaSeconds;
		Velocity -= FVector(0,0,Gravity) * DeltaSeconds;
		MortarRoot.WorldRotation = Velocity.Rotation();

		FHazeTraceDebugSettings Debug;
		Debug.Thickness = 2.5;
		Debug.TraceColor = FLinearColor::Red;
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(Initiator);
		TraceSettings.UseLine();
		TraceSettings.DebugDraw(Debug);

		FHitResult Hit = TraceSettings.QueryTraceSingle(MortarRoot.WorldLocation, MortarRoot.WorldLocation + (Velocity * DeltaSeconds));

		if (Hit.bBlockingHit)
		{
			auto HealthComp = UPlayerHealthComponent::Get(Hit.Actor);
			if (HealthComp != nullptr)
			{
				HealthComp.DamagePlayer(0.2, nullptr, nullptr, true);
			}
			
			FOnCrystalSiegerMortarImpactParams Params;
			Params.ImpactLocation = Hit.ImpactPoint;
			Params.ImpactRotation = Hit.ImpactNormal.Rotation();
			UCrystalSiegerMortarEffectHandler::Trigger_MortarImpact(this, Params);
			DestroyActor();
		}
	}
};