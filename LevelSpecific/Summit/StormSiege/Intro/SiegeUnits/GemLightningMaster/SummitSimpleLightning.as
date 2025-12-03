class ASummitSimpleLightning : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LightningComp;
	default LightningComp.SetAutoActivate(false);

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UCapsuleComponent CapsuleComp;
	// default CapsuleComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	// default CapsuleComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default CapsuleComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UStaticMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	float RandomMax = 1.25;

	UPROPERTY(EditAnywhere)
	float FireRate = 0.5;

	UPROPERTY(EditAnywhere)
	float Width = 2.0;

	UPROPERTY(EditAnywhere)
	float EndDistance = 35000.0;

	UPROPERTY(EditAnywhere)
	bool bDEBUG;

	float Damage = 0.4;

	float DelayTime;

	float FireTime;

	FVector TraceEnd;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DelayTime = Math::RandRange(0.0, RandomMax);
		SetActorTickEnabled(false);
		SetActorHiddenInGame(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// FHazeTraceDebugSettings Debug;
		// Debug.Thickness = 100.0;
		// Debug.TraceColor = FLinearColor::Red;
		
		FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
		TraceSettings.UseBoxShape(FVector(300.0));
		TraceSettings.IgnoreActor(this);
		// TraceSettings.DebugDraw(Debug);
		TraceEnd = ActorLocation + ActorUpVector * EndDistance;
		FHitResultArray Hits = TraceSettings.QueryTraceMulti(LightningComp.WorldLocation, TraceEnd);
		
		for (FHitResult Hit : Hits)
		{
			if (Hit.bBlockingHit)
			{
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
				if (Player != nullptr)
				{
					Player.DamagePlayerHealth(Damage);
					Player.AddDamageInvulnerability(this, 1.0);
				}
			}
		}
	}

	UFUNCTION()
	void SummontLightningPoint()
	{
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
		LightningComp.SetFloatParameter(n"BeamWidth", Width / 1.5);
		LightningComp.SetFloatParameter(n"JitterWidth", Width);
		TraceEnd = ActorLocation + ActorUpVector * EndDistance;
		LightningComp.SetNiagaraVariableVec3("End", TraceEnd);
		LightningComp.Activate();
	}
};