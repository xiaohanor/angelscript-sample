class ASummitAirCurrentWindUp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Meshroot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PullRoot;

	UPROPERTY()
	FVector Startloc;
	FVector Targetloc;

	UPROPERTY(EditAnywhere)
	ASummitAirCurrent PairedCurrent;

	UPROPERTY(EditAnywhere)
	APulleyInteraction Pulley;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};