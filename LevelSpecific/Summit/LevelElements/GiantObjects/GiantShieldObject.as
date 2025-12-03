class AGiantShieldObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectBobbingComponent Bobbing;

	UPROPERTY(DefaultComponent, Attach = Bobbing)
	USceneComponent MeshRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};