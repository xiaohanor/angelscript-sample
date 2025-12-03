class ASummitTopplingPillar02 : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshTarget;


	UPROPERTY()
	FRotator StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartRotation = MeshRoot.RelativeRotation;
	}
};