class ADentistCutsceneBoss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent MouthGuardRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	USceneComponent JawRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};