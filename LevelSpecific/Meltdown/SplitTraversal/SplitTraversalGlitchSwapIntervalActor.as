class ASplitTraversalGlitchSwapIntervalActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	UNiagaraSystem TelegraphEffect;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem DisappearEffect;
	UPROPERTY(EditAnywhere)
	UNiagaraSystem AppearEffect;

	UPROPERTY(EditAnywhere)
	float SwapInterval = 3.0;
	UPROPERTY(EditAnywhere)
	float TelegraphDuration = 3.0;
	UPROPERTY(EditAnywhere)
	float StartOffset = 0.0;

	float Timer = 0.0;
	EHazeWorldLinkLevel CurrentLevel;
	bool bBlocksFollow = false;

	TArray<USceneComponent> EffectPositions;
	TArray<USceneComponent> Attachments;
	TArray<FVector> Jitter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentLevel = WorldLink::GetClosestAnchor(ActorLocation).AnchorLevel;
		Timer -= StartOffset;

		for (int i = 0, Count = Root.NumChildrenComponents; i < Count; ++i)
		{
			auto Child = Root.GetChildComponent(i);
			if (Child.Owner == this)
			{
				if (Child.IsA(UNiagaraComponent))
					EffectPositions.Add(Child);
			}
			else
			{
				EffectPositions.Add(Child);
				Attachments.Add(Child);
				Jitter.Add(FVector::ZeroVector);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		if (Timer >= SwapInterval)
		{
			SwapWorlds();
			Timer = 0.0;
		}
		else if (Timer >= SwapInterval - TelegraphDuration)
		{
			for (int i = 0, Count = Attachments.Num(); i < Count; ++i)
			{
				FVector BaseLocation = Attachments[i].WorldLocation - Jitter[i];

				float TelegraphAlpha = (Timer - SwapInterval + TelegraphDuration) / TelegraphDuration;
				float JitterOffset = Math::Wrap(i * 177.0, 0.0, PI);
				Jitter[i] = FVector(0, 0, Math::Sin((Math::Pow(TelegraphAlpha, 2.0) + JitterOffset) * 80.0) * 10.0 * TelegraphAlpha);

				Attachments[i].WorldLocation = BaseLocation + Jitter[i];
			}
		}

		if (bBlocksFollow && Timer > 0.1)
		{
			bBlocksFollow = false;
			SetComponentsFollowable(true);
		}
	}

	void SwapWorlds()
	{
		bBlocksFollow = true;
		SetComponentsFollowable(false);

		for (int i = 0, Count = EffectPositions.Num(); i < Count; ++i)
			Niagara::SpawnOneShotNiagaraSystemAtLocation(DisappearEffect, EffectPositions[i].WorldLocation);

		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();
		auto TargetLevel = Manager.GetOtherSplit(CurrentLevel);
		ActorLocation = Manager.Position_Convert(ActorLocation, CurrentLevel, TargetLevel);
		CurrentLevel = TargetLevel;

		for (int i = 0, Count = EffectPositions.Num(); i < Count; ++i)
		{
			if (AppearEffect != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(AppearEffect, EffectPositions[i].WorldLocation);
			if (TelegraphEffect != nullptr)
				Niagara::SpawnOneShotNiagaraSystemAtLocation(TelegraphEffect, EffectPositions[i].WorldLocation);
		}
	}

	void SetComponentsFollowable(bool bFollowable)
	{
		TArray<USceneComponent> Comps;
		Comps.Reserve(32);
		Comps.Add(RootComponent);

		for (int CheckIndex = 0; CheckIndex < Comps.Num(); ++CheckIndex)
		{
			USceneComponent Comp = Comps[CheckIndex];
			
			// Recurse through children of this component
			for (int i = 0, Count = Comp.GetNumChildrenComponents(); i < Count; ++i)
			{
				auto Child = Comp.GetChildComponent(i);
				if (Child != nullptr)
					Comps.AddUnique(Child);
			}

			// Set the flag
			if (bFollowable)
				Comp.AddTag(n"InheritHorizontalMovementIfGround");
			else
				Comp.RemoveTag(n"InheritHorizontalMovementIfGround");
		}
	}
};