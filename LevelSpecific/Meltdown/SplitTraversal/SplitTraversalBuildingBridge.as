class ASplitTraversalBuildingBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
#endif

	UPROPERTY(EditAnywhere)
	UNiagaraSystem AppearEffect;

	TArray<UPrimitiveComponent> ScifiPrimitives;
	TArray<UPrimitiveComponent> FantasyPrimitives;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0, Count = Root.NumChildrenComponents; i < Count; ++i)
		{
			auto Child = Root.GetChildComponent(i);
			auto PrimComp = Cast<UPrimitiveComponent>(Child);
			if (PrimComp == nullptr)
				continue;

			auto Anchor = WorldLink::GetClosestAnchor(Child.WorldLocation);
			if (Anchor.AnchorLevel == EHazeWorldLinkLevel::SciFi)
				ScifiPrimitives.Add(PrimComp);
			else
				FantasyPrimitives.Add(PrimComp);
		}

		for (auto Prim : FantasyPrimitives)
		{
			Prim.AddComponentVisualsBlocker(this);
			Prim.AddComponentCollisionBlocker(this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		auto Manager = ASplitTraversalManager::GetSplitTraversalManager();

		for (auto Prim : FantasyPrimitives)
		{
			if (!Prim.bHiddenInGame)
				continue;

			FBox RelativeBox = Prim.BoundingBoxRelativeToOwner;

			FTransform PrimTransform = Prim.WorldTransform;
			PrimTransform.Location = Manager.Position_FantasyToScifi(PrimTransform.Location);

			FVector MioLocalTransform = PrimTransform.InverseTransformPosition(Game::Mio.ActorLocation);
			MioLocalTransform.Z = RelativeBox.Max.Z - 0.001;

			if (RelativeBox.IsInsideOrOn(MioLocalTransform))
			{
				Niagara::SpawnOneShotNiagaraSystemAtLocation(AppearEffect, Prim.WorldLocation);
				Prim.RemoveComponentCollisionBlocker(this);
				Prim.RemoveComponentVisualsBlocker(this);
			}
		}
	}
};