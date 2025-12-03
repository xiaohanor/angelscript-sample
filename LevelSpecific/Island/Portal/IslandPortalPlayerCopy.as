class AIslandPortalPlayerCopy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.ShadowPriority = EShadowPriority::Player;

	AHazePlayerCharacter CopyPlayer;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void Init(AHazePlayerCharacter Player)
	{
		CopyPlayer = Player;
		Mesh.SkeletalMeshAsset = CopyPlayer.Mesh.GetSkeletalMeshAsset();
		Mesh.SetLeaderPoseComponent(CopyPlayer.Mesh);
	}
};