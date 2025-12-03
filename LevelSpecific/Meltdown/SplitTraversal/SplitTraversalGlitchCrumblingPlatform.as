class ASplitTraversalGlitchCrumblingPlatform : AWorldLinkDoubleActor
{
	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	UNiagaraSystem DisappearEffect;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem AppearEffect;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 1.0;

	float Timer = 0.0;
	EHazeWorldLinkLevel CurrentLevel;

	FVector Jitter;
	bool bTriggered = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpact");

		CurrentLevel = EHazeWorldLinkLevel::SciFi;
		ToggleRoot(FantasyRoot, false);
	}

	UFUNCTION()
	private void OnGroundImpact(AHazePlayerCharacter Player)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		if (Manager.GetSplitForPlayer(Player) == CurrentLevel)
			bTriggered = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bTriggered)
		{
			Timer += DeltaSeconds;

			if (Timer >= TelegraphDuration)
			{
				SwapWorlds();
				Timer = 0.0;
			}
			else
			{
				FVector BaseLocation = ActorLocation - Jitter;

				float TelegraphAlpha = Timer / TelegraphDuration;
				Jitter = FVector(0, 0, Math::Sin((Math::Pow(TelegraphAlpha, 2.0)) * 80.0) * 10.0 * TelegraphAlpha);

				ActorLocation = BaseLocation + Jitter;
			}
		}

	}

	void ToggleRoot(USceneComponent Component, bool bVisible)
	{
		TArray<USceneComponent> Comps;
		Component.GetChildrenComponents(true, Comps);

		for (auto Comp : Comps)
		{
			UPrimitiveComponent PrimComp = Cast<UPrimitiveComponent>(Comp);
			if (PrimComp != nullptr)
			{
				PrimComp.SetHiddenInGame(!bVisible);
				PrimComp.SetCollisionEnabled(bVisible ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
			}
		}
	}

	void SwapWorlds()
	{
		bTriggered = false;

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();

		auto TargetLevel = Manager.GetOtherSplit(CurrentLevel);
		CurrentLevel = TargetLevel;

		if (CurrentLevel == EHazeWorldLinkLevel::Fantasy)
		{
			ToggleRoot(ScifiRoot, false);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DisappearEffect, ScifiRoot.WorldLocation);

			ToggleRoot(FantasyRoot, true);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(AppearEffect, FantasyRoot.WorldLocation);

		}
		else
		{
			ToggleRoot(FantasyRoot, false);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DisappearEffect, FantasyRoot.WorldLocation);

			ToggleRoot(ScifiRoot, true);
			Niagara::SpawnOneShotNiagaraSystemAtLocation(AppearEffect, ScifiRoot.WorldLocation);
		}
	}
};