event void FOnStormSiegeGuardianDefeated();

class AStormSiegeGuardian : AHazeActor
{
	UPROPERTY()
	FOnStormSiegeGuardianDefeated OnStormSiegeGuardianDefeated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectBobbingComponent BobComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));
	default Visual.SetRelativeLocation(FVector(0.0, 0.0, 4500.0));
#endif

	UPROPERTY(DefaultComponent)
	UStormSiegeMagicBarrierResponseComponent MagicBarrierResponseComp;

	UPROPERTY()
	TSubclassOf<ASummitNightQueenGem> GemClass;
	ASummitNightQueenGem Gem;
	AStormSiegeMetalFortification Metal;
	UPROPERTY(EditAnywhere)
	TSubclassOf<AStormSiegeMetalFortification> MetalClass;

	uint GemId = 0; 
	uint MetalId = 0; 

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;
	UHazeSplineComponent SplineComp;

	FSplinePosition SplinePos;

	float Speed = 1800.0;

	UFUNCTION()
	void SpawnPieces()
	{
		if (Gem == nullptr)
		{
			Gem = SpawnActor(GemClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
			Gem.MakeNetworked(this, n"Gem", GemId);
			GemId++;
			Gem.AttachToComponent(BobComp);
			FinishSpawningActor(Gem);
		}

		if (Metal == nullptr)
		{
			Metal = SpawnActor(MetalClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
			Metal.MakeNetworked(this, n"Metal", MetalId);
			Metal.AttachToComponent(BobComp);	
			Metal.OwningGem = Gem;
			FinishSpawningActor(Metal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPieces();

		SplineComp = SplineActor.Spline;
		Gem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
		
		// FStormSiegeGuardianTendrilParams Params;
		// Params.AttachComponent = AttachRoot;
		// Params.MagicBarrier = MagicBarrier;
		// UStormSiegeGuardianEffectHandler::Trigger_SpawnTendril(this, Params);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (SplineComp == nullptr)
			return;

		SplinePos.Move(Speed * DeltaSeconds);
		ActorLocation = SplinePos.WorldLocation;
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		// UStormSiegeGuardianEffectHandler::Trigger_DestroyTendril(this);
		SetActorTickEnabled(false);
		OnStormSiegeGuardianDefeated.Broadcast();
		MagicBarrierResponseComp.TriggerTarget();
	}
}