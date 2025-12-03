class APigMazeAppleSliceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
	

	UPROPERTY()
	FPigMazeAppleSliceEvent OnAllSlicesCollected;

	//TArray<APigMazeAppleSlice> AppleSlices;
	int SlicesCollected = 0;

	bool bAllSlicesCollected = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TListedActors<APigMazeAppleSlice> AppleSlices;
		for (APigMazeAppleSlice Slice : AppleSlices)
		{
			Slice.OnCollected.AddUFunction(this, n"SliceCollected");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void SliceCollected()
	{
		if (bAllSlicesCollected)
			return;

		SlicesCollected++;
		TListedActors<APigMazeAppleSlice> AppleSlices;
		if (SlicesCollected >= AppleSlices.Num())
		{
			AllSlicesCollected();
		}
	}

	void AllSlicesCollected()
	{
		if (bAllSlicesCollected)
			return;

		bAllSlicesCollected = true;

		OnAllSlicesCollected.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// PrintToScreen("" + SlicesCollected);
	}
}