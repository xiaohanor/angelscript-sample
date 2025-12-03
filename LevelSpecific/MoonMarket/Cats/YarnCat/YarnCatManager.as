struct FYarnCatData
{
	UPROPERTY(EditAnywhere)
	APlayerTrigger Trigger;

	UPROPERTY(EditAnywhere)
	AYarnMoonMarketCat YarnCat;

	void DisableInteraction(FInstigator Instigator)
	{
		if (YarnCat != nullptr)
			YarnCat.InteractComp.Disable(Instigator);
	}

	void AddDisabler(FInstigator Instigator)
	{
		if (Trigger != nullptr)
			Trigger.AddActorDisable(Instigator);
		if (YarnCat != nullptr)
			YarnCat.AddActorDisable(Instigator);
	}

	void RemoveDisabler(FInstigator Instigator)
	{
		if (Trigger != nullptr)
			Trigger.RemoveActorDisable(Instigator);
		if (YarnCat != nullptr)
			YarnCat.RemoveActorDisable(Instigator);
	}
}

class AYarnCatManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditInstanceOnly)
	TArray<FYarnCatData> YarnCats;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (FYarnCatData& Params : YarnCats)
		{
			Params.DisableInteraction(this);
			Params.AddDisabler(this);
		}
	}

	void ActivateCats()
	{
		for (FYarnCatData& Params : YarnCats)
			Params.RemoveDisabler(this);
	}
};