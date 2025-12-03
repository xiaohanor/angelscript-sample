class AGameShowArenaDecalTestPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent PlatformMesh;

	UGameShowArenaDisplayDecalPlatformComponent DisplayComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto DisplayComp = UGameShowArenaDisplayDecalPlatformComponent::Create(this);
		//DisplayComp.TargetMeshComp = PlatformMesh;
	}
};