class ASplitBonanzaOffsetManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;

	UPROPERTY(EditAnywhere)
	int EditorOrder;
	UPROPERTY(EditAnywhere)
	FString EditorGlyph;
	UPROPERTY(EditAnywhere)
	FLinearColor EditorColor;

	bool bShowInOverlay = true;
#endif

	bool bActivatedInManager = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = ASplitBonanzaManager::Get();
		if (Manager != nullptr)
			Manager.ActivateBonanzaOnOffsetActor(this);
	}

	void ActivateSplitBonanza()
	{
		if (bActivatedInManager)
			return;
		bActivatedInManager = true;

		FVector MoveOffset = Progress::GetLevelStreamingOffset(Level) - ActorLocation;

		for (AActor Actor : Level.Actors)
		{
			if (Actor == nullptr)
				continue;

			USceneComponent ActorRoot = Actor.RootComponent;
			if (ActorRoot == nullptr)
				continue;

			if (Actor.IsA(ALight))
				continue;

			TArray<UPrimitiveComponent> Primitives;
			Actor.GetComponentsByClass(Primitives);

			for (UPrimitiveComponent PrimComp : Primitives)
				PrimComp.SetLightmapType(ELightmapType::ForceSurface);

			if (ActorRoot.Mobility == EComponentMobility::Static)
			{
				ActorRoot.SetMobility(EComponentMobility::Movable);
				ActorRoot.WorldLocation = ActorRoot.WorldLocation + MoveOffset;
				ActorRoot.SetMobility(EComponentMobility::Static);
			}
			else
			{
				ActorRoot.WorldLocation = ActorRoot.WorldLocation + MoveOffset;
			}
		}
	}

#if EDITOR
	int opCmp(ASplitBonanzaOffsetManager Other) const
	{
		if (EditorOrder < Other.EditorOrder)
			return -1;
		else if (EditorOrder > Other.EditorOrder)
			return 1;
		else
			return EditorGlyph.Compare(Other.EditorGlyph);
	}
#endif
}