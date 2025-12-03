class ATreeGuardianClimbPoleMonkeySmash : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UTundraPlayerSnowMonkeyGroundSlamResponseComponent SlampComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};