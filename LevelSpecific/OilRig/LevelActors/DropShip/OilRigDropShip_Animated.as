class AOilRigDropShip_Animated : AOilRigDropShip
{
	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(EditAnywhere)
	bool bAttachActorsToBaseSocket = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if (bAttachActorsToBaseSocket)
		{
			TArray<AActor> AttachedActors;
			GetAttachedActors(AttachedActors);
			for (AActor Actor : AttachedActors)
			{
				Actor.AttachToComponent(SkelMeshComp, n"Base", EAttachmentRule::KeepWorld);
			}
		}
	}
}