class ASoftSplitPlayerCopy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.ShadowPriority = EShadowPriority::Player;

	AHazePlayerCharacter CopyPlayer;
	ASoftSplitManager Manager;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;
	float TimeSinceDead = 0.0;

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

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = ASoftSplitManager::GetSoftSplitManger();
		if (Manager == nullptr)
			return;

		FTransform Transform = CopyPlayer.ActorTransform;
		Transform.Location = Manager.Position_Convert(
			Transform.Location,
			Manager.GetSplitForPlayer(CopyPlayer),
			Manager.GetSplitForPlayer(CopyPlayer.OtherPlayer),
		);

		SetActorTransform(Transform);

		if (CopyPlayer.IsPlayerDeadOrRespawning())
		{
			SetActorHiddenInGame(true);
			TimeSinceDead = 0.0;
		}
		else
		{
			TimeSinceDead += DeltaSeconds;
			if (TimeSinceDead > 2.0)
				SetActorHiddenInGame(false);
		}
	}
};