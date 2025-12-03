class ADarkCaveSpiritStatueManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent VisualComp;
	default VisualComp.SetWorldScale3D(FVector(15));
	default VisualComp.SpriteName = "AnchorActor";
#endif

	TArray<ADarkCaveSpiritStatue> Statues;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Statues = TListedActors<ADarkCaveSpiritStatue>().GetArray();
	}

	UFUNCTION()
	bool HasCompletedAllStatues()
	{
		for (ADarkCaveSpiritStatue Statue : Statues)
		{
			if (!Statue.bSpiritFreed)
				return false;
		}

		return true;
	}
};