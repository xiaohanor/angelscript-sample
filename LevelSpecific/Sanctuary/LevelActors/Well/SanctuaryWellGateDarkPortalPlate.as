class ASanctuaryWellGateDarkPortalPlate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UDarkPortalAutoAimComponent DarkPortalAutoAimComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};