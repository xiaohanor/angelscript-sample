class AInfuseEssence : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USanctuaryFloatingSceneComponent FloatingComp;

	UPROPERTY()
	UNiagaraSystem VFXSystem;

	UPROPERTY()
	float AccelerationSpeed = 500.0;

	UPROPERTY()
	float ConsumeRadius = 50.0;

	FVector TargetLocation;

	float LerpSpeed = 0.0;

	bool bTargetCompanion = false;

	AHazeActor Companion;

	AInfuseEssenceManager Manager;
	AInfuseEssenceBothManager BothManager;
	private TArray<FInstigator> DisableVisibleInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION()
	void TargetCompanion(AHazeActor Actor)
	{
		Companion = Actor;
		LerpSpeed = 0.0;
		bTargetCompanion = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		HideInCutscene();
		UpdateHidden();
		
		if (bTargetCompanion)
		{
			LerpSpeed += DeltaSeconds * AccelerationSpeed;

			FVector DeltaMove = (Companion.ActorLocation - ActorLocation).GetSafeNormal() * LerpSpeed * DeltaSeconds;
			
			AddActorWorldOffset(DeltaMove);

			if (Companion.ActorLocation.Distance(ActorLocation) < ConsumeRadius)
				Consumed();
		}
	}

	UFUNCTION()
	private void Consumed()
	{
		if(Manager!=nullptr)
		{
			Manager.EssenceConsumed(Companion);
			AddActorDisable(Manager);
		}
		
		if(BothManager!=nullptr)
		{
			BothManager.EssenceConsumed(Companion);
			AddActorDisable(BothManager);
		}
	
		bTargetCompanion = false;
		Niagara::SpawnOneShotNiagaraSystemAttached(VFXSystem, Companion.RootComponent);
	}

	
	void AddHide(FInstigator Instigator)
	{
		DisableVisibleInstigators.AddUnique(Instigator);
	}

	void RemoveHide(FInstigator Instigator)
	{
		if (DisableVisibleInstigators.Contains(Instigator))
			DisableVisibleInstigators.Remove(Instigator);
	}

	private void HideInCutscene()
	{
		if (Game::Zoe.bIsControlledByCutscene)
			AddHide(this);
		else
			RemoveHide(this);
	}

	private void UpdateHidden()
	{
		if (DisableVisibleInstigators.Num() > 0 && !IsHidden())
			SetActorHiddenInGame(true);
		else if (DisableVisibleInstigators.Num() == 0 && IsHidden())
			SetActorHiddenInGame(false);
	}
		
};