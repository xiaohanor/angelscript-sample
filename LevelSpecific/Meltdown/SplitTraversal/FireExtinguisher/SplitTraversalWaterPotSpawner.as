struct FSplitTraversalWaterPotSpawnerEventParams
{
	UPROPERTY()
	ASplitTraversalWaterPot WaterPot;

	FSplitTraversalWaterPotSpawnerEventParams(ASplitTraversalWaterPot _WaterPot)
	{
		WaterPot = _WaterPot;
	}
}

class USplitTraversalWaterPotSpawnerEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void OnSpawnPot(FSplitTraversalWaterPotSpawnerEventParams Params) {};

	UFUNCTION(BlueprintEvent)
	void OnPotDestroyed(FSplitTraversalWaterPotSpawnerEventParams Params) {};	
}

class ASplitTraversalWaterPotSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	TSubclassOf<ASplitTraversalWaterPot> WaterPotClass;

	UPROPERTY()
	TArray<TSubclassOf<ASplitTraversalWaterPot>> WaterPotClasses;
	int PotMaterialIndex;

	UPROPERTY(EditInstanceOnly)
	AActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditInstanceOnly)
	ASplitTraversalFireGate FireGate;

	UPROPERTY(EditAnywhere)
	float SpawnInterval = 3.0;

	int PotCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		SplineComp = Spline::GetGameplaySpline(SplineActor, this);
		Timer::SetTimer(this, n"ControlSpawnPot", SpawnInterval, true);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSpawnPot(float CrumbStartTime)
	{
		PotMaterialIndex++;
		if (PotMaterialIndex > WaterPotClasses.Num() - 1)
			PotMaterialIndex = 0;

		auto WaterPot = SpawnActor(WaterPotClasses[PotMaterialIndex], bDeferredSpawn = true);
		WaterPot.CrumbTimeOfStart = CrumbStartTime;
		WaterPot.SplineComp = SplineComp;
		WaterPot.FireGate = FireGate;
		WaterPot.Spawner = this;
		WaterPot.MakeNetworked(this, PotCount);
		PotCount++;
		FinishSpawningActor(WaterPot);

		USplitTraversalWaterPotSpawnerEventHandler::Trigger_OnSpawnPot(this, FSplitTraversalWaterPotSpawnerEventParams(WaterPot));
	}

	UFUNCTION()
	private void ControlSpawnPot()
	{
		if (HasControl())
			CrumbSpawnPot(Time::GetActorControlCrumbTrailTime(Game::Zoe));
	}
};