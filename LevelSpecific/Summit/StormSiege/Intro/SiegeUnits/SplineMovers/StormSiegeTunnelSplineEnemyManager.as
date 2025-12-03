class AStormSiegeTunnelSplineEnemyManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual; 
	default Visual.SetWorldScale3D(FVector(20.0));
#endif

	UPROPERTY(DefaultComponent, ShowOnActor)
	UStormSiegeUnitSplineMovementComponent SplineMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StormSiegeTunnelSplineSpawnGemCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormSiegeTunnelSplineSpawnMetalCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"StormSiegeTunnelSplineSpawnMetalGemCapability");

	UPROPERTY()
	TSubclassOf<AStormSiegeGemSplineMover> GemEnemyClass;
	UPROPERTY()
	TSubclassOf<AStormSiegeMetalSplineMover> MetalEnemyClass;
	UPROPERTY()
	TSubclassOf<AStormSiegeMetalGemSplineMover> MetalGemEnemyClass;

	bool bIsFinalPhase;
	bool bIsSpawnActive;

	TArray<AStormSiegeGemSplineMover> GemArray;
	TArray<AStormSiegeMetalSplineMover> MetalArray;
	TArray<AStormSiegeMetalGemSplineMover> MetalGemArray;

	int MaxGemEnemies = 2;
	int MaxMetalEnemies = 2;
	int MaxMetalGemEnemies = 2;
	int CurrentGemEnemies;
	int CurrentMetalEnemies;
	int CurrentMetalGemEnemies;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Debug::DrawDebugSphere(ActorLocation, 550.0, 12, FLinearColor::Red, 15.0);
	}

	UFUNCTION()
	void ActivateEnemySpawns()
	{
		SplineMoveComp.ActivateSplineMovement();
		bIsSpawnActive = true;

		// for (int i = 0; i < MaxGemEnemies; i++)
		// {
		// 	SpawnGem();
		// }

		// for (int i = 0; i < MaxMetalEnemies; i++)
		// {
		// 	SpawnMetal();
		// }
	}

	UFUNCTION()
	void ActivateFinalPhase()
	{
		bIsFinalPhase = true;

		TArray<AStormSiegeGemSplineMover> NewGemArray = GemArray;
		TArray<AStormSiegeMetalSplineMover> NewMetalArray = MetalArray;

		GemArray.Empty();
		MetalArray.Empty();

		//Replace with desummon functionality
		for (AStormSiegeGemSplineMover Gem : NewGemArray)
		{
			if (HasControl())
				Gem.CrumbDestroyCrystal();
		}
		
		for (AStormSiegeMetalSplineMover Metal : NewMetalArray)
		{
			if (HasControl())
				Metal.Crumb_DestroyStormSiegeMetal();
		}
	}

	UFUNCTION()
	void DeactivateSpawns()
	{
		bIsSpawnActive = false;
		SplineMoveComp.DeactivateSplineMovement();

		TArray<AStormSiegeGemSplineMover> NewGemArray = GemArray;
		TArray<AStormSiegeMetalSplineMover> NewMetalArray = MetalArray;
		TArray<AStormSiegeMetalGemSplineMover> NewMetalGemEnemyArray = MetalGemArray;

		GemArray.Empty();
		MetalArray.Empty();
		MetalGemArray.Empty();

		for (AStormSiegeGemSplineMover Gem : NewGemArray)
		{
			if (HasControl())
				Gem.CrumbDeSummonEnemy();
		}

		for (AStormSiegeMetalSplineMover Metal : NewMetalArray)
		{
			if (HasControl())
				Metal.CrumbDeSummonEnemy();
		}

		for (AStormSiegeMetalGemSplineMover MetalGem : NewMetalGemEnemyArray)
		{
			if (HasControl())
				MetalGem.CrumbDesummonGemMetal();
		}
	}

	void SpawnGem()
	{
		AStormSiegeGemSplineMover NewGem = SpawnActor(GemEnemyClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
		NewGem.SplineMoveComp.Spline = SplineMoveComp.Spline;
		FinishSpawningActor(NewGem);
		NewGem.ActivateSplineMover();
		GemArray.Add(NewGem);
		NewGem.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
	}

	void SpawnMetal()
	{
		AStormSiegeMetalSplineMover NewMetal = SpawnActor(MetalEnemyClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
		NewMetal.SplineMoveComp.SplineComp = SplineMoveComp.SplineComp;
		FinishSpawningActor(NewMetal);
		NewMetal.ActivateSplineMover();
		MetalArray.Add(NewMetal);
		NewMetal.OnStormSiegeMetalDestroyed.AddUFunction(this, n"OnStormSiegeMetalDestroyed");
	}

	void SpawnMetalGem()
	{
		AStormSiegeMetalGemSplineMover NewMetalGem = SpawnActor(MetalGemEnemyClass, ActorLocation, ActorRotation, bDeferredSpawn = true);
		NewMetalGem.SplineMoveComp.SplineComp = SplineMoveComp.SplineComp;
		FinishSpawningActor(NewMetalGem);
		NewMetalGem.ActivateSplineMover();
		MetalGemArray.Add(NewMetalGem);
		NewMetalGem.OnStormSiegeMetalGemDestroyed.AddUFunction(this, n"OnStormSiegeMetalGemDestroyed");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitSiegeGem CrystalDestroyed)
	{
		AStormSiegeGemSplineMover Gem = Cast<AStormSiegeGemSplineMover>(CrystalDestroyed);

		if (GemArray.Contains(Gem))
			GemArray.Remove(Gem);
	}

	UFUNCTION()
	private void OnStormSiegeMetalDestroyed(AStormSiegeMetalFortification DestroyedMetal)
	{
		AStormSiegeMetalSplineMover Metal = Cast<AStormSiegeMetalSplineMover>(DestroyedMetal);
		
		if (MetalArray.Contains(Metal))
			MetalArray.Remove(Metal);
	}

	UFUNCTION()
	private void OnStormSiegeMetalGemDestroyed(AStormSiegeMetalGemSplineMover MetalGem)
	{
		if (MetalGemArray.Contains(MetalGem))
			MetalGemArray.Remove(MetalGem);
	}
	
	bool CanSpawnGem()
	{
		return GemArray.Num() < MaxGemEnemies;
	}

	bool CanSpawnMetal()
	{
		return MetalArray.Num() < MaxMetalEnemies;
	}

	bool CanSpawnMetalGem()
	{
		return MetalGemArray.Num() < MaxMetalGemEnemies;
	}
}