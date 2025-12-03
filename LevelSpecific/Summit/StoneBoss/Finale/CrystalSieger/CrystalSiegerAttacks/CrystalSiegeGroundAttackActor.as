class ACrystalSiegeGroundAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SpriteName = "ZoneAmbience";
	default Visual.SetWorldScale3D(FVector(0.75));
#endif	

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent ArrowComp;
	default ArrowComp.SetWorldScale3D(FVector(2.0));

	UPROPERTY()
	TSubclassOf<ACrystalSiegerSpike> CrystalSpikeClass;
	TArray<ACrystalSiegerSpike> CrystalSpikePool;

	//Optional spline
	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float SpikeAttackTime = 1.5;
	UPROPERTY(EditAnywhere)
	float SpikeAttackDuration = 0.75;

	bool bIsAttacking;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void FireAttack(float DelayTime = 0.0)
	{

	}

	void SpawnCrystalSpike(FVector Location, FRotator Rotation)
	{
		//Check if over 5, ensures pool has more than we need.
		//So that effects for completed pool actors have time to reset before being used again
		if (CrystalSpikePool.Num() > 5)
		{
			CrystalSpikePool[0].ActivateSpike(Location, Rotation, SpikeAttackTime, SpikeAttackDuration);
			CrystalSpikePool.RemoveAt(0);
		}
		else
		{
			auto Spike = SpawnActor(CrystalSpikeClass, Location, Rotation, bDeferredSpawn = true);
			Spike.AttackTime = SpikeAttackTime;
			Spike.AttackDuration = SpikeAttackDuration;
			FinishSpawningActor(Spike);
			Spike.OnCrystalSiegeSpikeCompletedAttack.AddUFunction(this, n"OnCrystalSiegeSpikeCompletedAttack");
		}
	}

	UFUNCTION()
	private void OnCrystalSiegeSpikeCompletedAttack(ACrystalSiegerSpike CompletedSpike)
	{
		CrystalSpikePool.AddUnique(CompletedSpike);
		CompletedSpike.OnCrystalSiegeSpikeCompletedAttack.Unbind(this, n"OnCrystalSiegeSpikeCompletedAttack");
	}
};