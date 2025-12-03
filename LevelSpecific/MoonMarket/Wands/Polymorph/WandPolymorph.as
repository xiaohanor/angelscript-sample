class AWandPolymorph : AWandBase
{
	UPROPERTY(Category = "Setup")
	TArray<TSubclassOf<AHazeActor>> PossibleMorphs;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComp;

	int CurrentMorphIndex = -1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}
	
	void StartCasting() override
	{
		Super::StartCasting();

		UMoonMarketPolymorphWandEventHandler::Trigger_StartCasting(this);
	}

	void FinishCasting(FSpellHitData Data) override
	{
		Super::FinishCasting(Data);

		UMoonMarketPolymorphWandEventHandler::Trigger_FinishCasting(this, Data);

		if(!HasControl())
			return;
		
		int NewMorphIndex = Math::WrapIndex(CurrentMorphIndex + 1, 0, PossibleMorphs.Num());
		TSubclassOf<AHazeActor> Morph = PossibleMorphs[NewMorphIndex];

		AActor HitActor = UWandPlayerComponent::Get(InteractingPlayer).TargetActor;
		if(HitActor != nullptr)
		{
			auto PolymorphComp = UPolymorphResponseComponent::Get(HitActor);
			if(PolymorphComp != nullptr)
			{
				PolymorphComp.NetRequestPolymorph(Morph, PlayerData.Player);
				CurrentMorphIndex = NewMorphIndex;
			}
		}
	}
};