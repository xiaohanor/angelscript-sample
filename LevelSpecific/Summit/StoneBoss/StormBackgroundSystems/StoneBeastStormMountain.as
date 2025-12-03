class AStoneBeastStormMountain : AHazeActor
{
	default ActorEnableCollision = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FRotator AddRotation = FRotator(0, Math::RandRange(-360, 360), 0);
		MeshRoot.RelativeRotation += AddRotation;
	}
};