class ASolarFlarePanelCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UAttachOwnerToParentComponent AttachComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USolarFlarePlayerCoverComponent CoverComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};