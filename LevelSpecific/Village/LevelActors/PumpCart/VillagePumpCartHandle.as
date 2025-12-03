class AVillagePumpCartHandle : AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Base")
	USceneComponent LeftHandle;

	UPROPERTY(DefaultComponent, Attach = "CharacterMesh0", AttachSocket = "Base")
	USceneComponent RightHandle;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeaturePumpCart Feature;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddLocomotionFeature(Feature, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RequestLocomotion(n"PumpCart", this);
	}
}