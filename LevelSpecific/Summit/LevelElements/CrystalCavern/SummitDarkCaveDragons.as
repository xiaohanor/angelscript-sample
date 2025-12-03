class ASummitDarkCaveDragons : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Dragon;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() 
	{
		
	}

	UFUNCTION(BlueprintCallable)
	void BP_CallEvent() 
	{
		BP_Activate();
	}
};