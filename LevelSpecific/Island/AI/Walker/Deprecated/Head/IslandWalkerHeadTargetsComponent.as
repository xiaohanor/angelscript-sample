event void IslandWalkerHeadTargetsDestroyedSignature();

class UIslandWalkerHeadForceFieldLocationComponent : USceneComponent
{
}

class UIslandWalkerHeadTargetsComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<AIslandWalkerHeadTarget> TargetClass;

	UBasicAIFleeingComponent FleeComp;
	private int DepletedNum = 0;
	private TArray<AIslandWalkerHeadTarget> HeadTargets;

	bool bRedDestroyed = false;
	bool bBlueDestroyed = false;

	IslandWalkerHeadTargetsDestroyedSignature OnDestroyed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FleeComp = UBasicAIFleeingComponent::Get(Owner);
		TArray<UIslandWalkerHeadForceFieldLocationComponent> Locations;
		Owner.GetComponentsByClass(Locations);

		bool bBlue = true;
		for(UIslandWalkerHeadForceFieldLocationComponent Location: Locations)
		{
			AIslandWalkerHeadTarget HeadTarget = SpawnActor(TargetClass, bDeferredSpawn = true);

			if(bBlue)
				HeadTarget.ForceFieldComp.Type = EIslandForceFieldType::Blue;
			else
				HeadTarget.ForceFieldComp.Type = EIslandForceFieldType::Red;
			bBlue = false;

			HeadTarget.ForceFieldComp.OnDepleted.AddUFunction(this, n"OnDepleted");
			HeadTarget.ForceFieldComp.Walker = Cast<AHazeActor>(Owner);
			
			FinishSpawningActor(HeadTarget);
			HeadTarget.AttachToComponent(Location);
			HeadTargets.Add(HeadTarget);
		}
		HideHeadTargets();
	}

	void ShowHeadTargets()
	{
		for(auto Target: HeadTargets)
		{
			Target.RemoveActorDisable(this);
		}
	}

	void HideHeadTargets()
	{
		for(auto Target: HeadTargets)
		{
			Target.AddActorDisable(this);
		}
	}

	UFUNCTION()
	private void OnDepleted(UIslandWalkerForceFieldComponent ForceFieldComponent)
	{
		if(ForceFieldComponent.Type == EIslandForceFieldType::Red)
			bRedDestroyed = true;
		else 
			bBlueDestroyed = true;

		DepletedNum++;
		if(DepletedNum >= 2)
			FleeComp.Flee();
		OnDestroyed.Broadcast();
	}
}