event void FOnSummitDarkCaveSpiritDestroyed(int Count);

class ASummitDarkCaveSpiritEventManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY()
	FOnSummitDarkCaveSpiritDestroyed OnSummitDarkCaveSpiritDestroyed;

	UPROPERTY(EditAnywhere)
	TArray<ADarkCaveSpiritStatue> SpiritStatues;

	int Count;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (ADarkCaveSpiritStatue Statue : SpiritStatues)
		{
			Statue.OnDarkCaveSpiritStatueDestroyed.AddUFunction(this, n"StatueDestroyed");
		}
	}

	UFUNCTION()
	private void StatueDestroyed()
	{
		Count++;
		OnSummitDarkCaveSpiritDestroyed.Broadcast(Count);
	}
};