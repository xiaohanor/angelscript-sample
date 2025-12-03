class ASkylineSentryBossForceField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent Collision;


	bool bForceFieldActive;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DeactivateForceField();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bForceFieldActive)
			return;
		
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(Collision);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(Game::Mio);

		

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit && Hit.Actor != nullptr)
			{
				
				USkylineSentryBossForceFieldResponseComponent ResponseComp = USkylineSentryBossForceFieldResponseComponent::Get(Hit.Actor);

				if(ResponseComp != nullptr)
				{
					Print("Actor: " + Hit.Actor);
					Hit.Actor.DestroyActor();
				}
			}
		}
	}

	void ActivateForceField()
	{
		bForceFieldActive = true;
		MeshComp.SetHiddenInGame(false, true);
	}

	void DeactivateForceField()
	{
		bForceFieldActive = false;
		MeshComp.SetHiddenInGame(true, true);
	}


}