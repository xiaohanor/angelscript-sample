class ATundraBossRunPastCorridorActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	bool bHasTriggered = false;
	bool bHasPlayedShake = false;
	float AnimationDuration = 1.5;

	FHazeTimeLike MoveIceKingTimelike;
	default MoveIceKingTimelike.Duration = 0.5;

	default ActorHiddenInGame = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		MoveIceKingTimelike.BindUpdate(this, n"MoveIceKingTimelikeUpdate");
		MoveIceKingTimelike.BindFinished(this, n"MoveIceKingTimelikeFinished");

		MoveIceKingTimelike.SetPlayRate(1 / AnimationDuration);
	}


	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{
		if(bHasTriggered)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if(Player == nullptr)
			return;

		bHasTriggered = true;
		MoveIceKingTimelike.PlayFromStart();
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	private void MoveIceKingTimelikeUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(Math::Lerp(FVector::ZeroVector, FVector(6200, 0, 0), CurrentValue));

		if(CurrentValue > 0.5 && !bHasPlayedShake)
			PlayCameraShake();
	}

	void PlayCameraShake()
	{
		bHasPlayedShake = true;
		
		for(auto Player : Game::GetPlayers())
		{
			Player.PlayWorldCameraShake(CamShake, this, SkelMesh.WorldLocation, 1000, 3000);
		}
	}

	UFUNCTION()
	private void MoveIceKingTimelikeFinished()
	{
		SetActorHiddenInGame(true);
	}
};