
UCLASS(Abstract)
class AMoonMarketCatHolder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	private int CurrentCollectedCatsNumber = 0;


	UFUNCTION()
	void ReturnCat(AMoonMarketCat InCat)
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);

		check(CurrentCollectedCatsNumber < AttachedActors.Num());

		//Unhide the attached cat at current index
		AMoonMarketCat Cat = Cast<AMoonMarketCat>(AttachedActors[CurrentCollectedCatsNumber]);
		Cat.SkelMeshComp.SetVisibility(true);

		CurrentCollectedCatsNumber++;

		if(CurrentCollectedCatsNumber == AttachedActors.Num())
		{
			BP_AllCatsCollected();
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_AllCatsCollected(){}
};