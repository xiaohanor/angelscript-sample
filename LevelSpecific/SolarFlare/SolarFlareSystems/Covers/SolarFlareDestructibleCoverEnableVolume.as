class ASolarFlareDestructibleCoverEnableVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareDestructibleCover> Covers;

	TArray<AHazePlayerCharacter> Players;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		BoxComp.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Players.AddUnique(Player);

		for (ASolarFlareDestructibleCover Cover : Covers)
			Cover.SetBreakActiveState(true);
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
			Players.Remove(Player);

		if (Players.Num() == 0)
		{
			for (ASolarFlareDestructibleCover Cover : Covers)
				Cover.SetBreakActiveState(false);
		}
	}

	UFUNCTION(CallInEditor)
	void SetDestructbileCovers()
	{
	#if EDITOR

		Covers.Empty();
		TArray<ASolarFlareDestructibleCover> OverlappingActors = Editor::GetAllEditorWorldActorsOfClass(ASolarFlareDestructibleCover);

		FBox Box = FBox(-BoxComp.BoxExtent, BoxComp.BoxExtent);

		for (auto It : OverlappingActors)
		{
			auto Actor = Cast<ASolarFlareDestructibleCover>(It);
			FVector LocalPosition = BoxComp.WorldTransform.InverseTransformPosition(Actor.ActorLocation);
			
			if (Actor.Level != this.Level)
				continue;

			if (Box.IsInside(LocalPosition))
				Covers.Add(Actor);
		}

	#endif
	}
}