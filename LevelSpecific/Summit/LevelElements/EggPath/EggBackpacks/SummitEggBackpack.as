class ASummitEggBackpack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComp;
	default MeshOffsetComp.RelativeRotation = FRotator(0, 0, 0);

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeSkeletalMeshComponentBase BackpackMesh;
	default BackpackMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = BackpackMesh, AttachSocket = "Egg")
	UStaticMeshComponent EggMesh;
	default EggMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

	UPROPERTY(DefaultComponent)
	UHazeMeshPoseDebugComponent PoseDebugComp;

	UPROPERTY(DefaultComponent)
	UHazeMovementAudioComponent MoveAudioComp;

	UPROPERTY(DefaultComponent)
	USoundDefContextComponent SoundDefComp;

	void SetupSoundDef()
	{
		auto PlayerMoveComp = UHazeMovementAudioComponent::Get(GetAttachParentActor());
		PlayerMoveComp.LinkMovementRequests(MoveAudioComp);
	}
};