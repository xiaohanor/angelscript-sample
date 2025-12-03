class ASanctuaryBossMedallionHealthActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossArenaHydraHealthBarComponent HealthBarComp;
	default HealthBarComp.HealthBarSegments = 6;

	ASanctuaryBossMedallionHydraReferences Refs;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
	}

	void LateBeginPlay()
	{
		Refs.HydraAttackManager.OnPhaseChanged.AddUFunction(this, n"PhaseChanged");
	}

	UFUNCTION()
	private void PhaseChanged(EMedallionPhase Phase, bool bNaturalProgression)
	{
		if (Phase > EMedallionPhase::GloryKill3)
		{
			AddActorDisable(this);
			SetAutoDestroyWhenFinished(true);
		}
		else
		{
			int KilledHeads = MedallionStatics::BP_GetNumKilledHeads(Phase);
			SetProgress(KilledHeads);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetProgress(int KilledHeads)
	{
		float KilledHeadsFloat = Math::FloorToFloat(KilledHeads);
		float TotalHeads = Math::FloorToFloat(CompanionAviation::HealthBarHeads);
		float Damage = KilledHeadsFloat / TotalHeads;
		HealthComp.SetCurrentHealth(1.0 - Damage);
		HealthBarComp.RefreshHealthValue();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (CacheRefs())
			SetActorTickEnabled(false);
	}

	private bool CacheRefs()
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> LevelReferences;
		if (LevelReferences.Num() == 0)
			return false;
		Refs = LevelReferences.Single;
		LateBeginPlay();
		return true;
	}

	
};