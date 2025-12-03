class ASummitRaftKillCollision : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CollisionBox;
	default CollisionBox.SetCollisionProfileName(n"Trigger");

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
		CollisionBox.SetCollisionResponseToChannel(ECollisionChannel::ECC_Vehicle, ECollisionResponse::ECR_Overlap);
		CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
				   UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
				   const FHitResult&in SweepResult)
	{
		AWaveRaft Raft = Cast<AWaveRaft>(OtherActor);
		if (Raft == nullptr)
			return;

		if (HasControl())
			Raft.CrumbExplodeWaveRaft();
	}
};