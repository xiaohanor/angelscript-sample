class AGameShowArenaTextPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StaticMesh;
	default StaticMesh.Mobility = EComponentMobility::Static;
	
	UPROPERTY(DefaultComponent, Attach = StaticMesh)
	UBoxComponent BoxComp2;
	default BoxComp2.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent)
	UGameShowArenaDisplayDecalPlatformComponent DecalComp;

	default BoxComp2.bGenerateOverlapEvents = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DecalComp.AssignTarget(StaticMesh, nullptr);
	}
};