class ATundraBossIceKingSlideActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.bHiddenInGame = true;
	default SkelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"TundraBossIceKingSlideActorCapability");

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Animation;

	TArray<AHazePlayerCharacter> PlayerArray;
	bool bShouldPlayAnimation = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player == nullptr)
			return;

		PlayerArray.AddUnique(Player);

		if(PlayerArray.Num() >= 2)
		{
			//Activates a capability
			bShouldPlayAnimation = true;
		}
	}
};