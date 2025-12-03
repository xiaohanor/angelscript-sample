class AFallingBobbingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USummitObjectBobbingComponent BobComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent CheckPlayersAreInsideOverlap;
	default CheckPlayersAreInsideOverlap.bDisableUpdateOverlapsOnComponentMove = true;
	default CheckPlayersAreInsideOverlap.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CheckPlayersAreInsideOverlap.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(EditAnywhere)
	TArray<ARespawnPointVolume> ToDisableRespawnVolumes;

	UPROPERTY(EditAnywhere)
	ARespawnPoint ToEnableRespawnPoint;

	UPROPERTY()
	TArray<AHazePlayerCharacter> PlayersInside;

	TArray<UStaticMeshComponent> MeshComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CheckPlayersAreInsideOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		CheckPlayersAreInsideOverlap.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
		GetComponentsByClass(MeshComps);
	}

	UFUNCTION()
	void DisableRespawnPointOnDestruction()
	{
		// for (AHazePlayerCharacter Player : Game::Players)
		// 	DisableRespawnPoint.DisableForPlayer(Player, this);
	}

	UFUNCTION()
	void DestroyObject()
	{
		UFallingBobbingObjectEffectHandler::Trigger_OnFallingBobbingDestroyed(this, FOnFallingBobbingObjectDestroyedParams(ActorLocation));
		CheckPlayersAreInsideOverlap.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		for (UStaticMeshComponent Comp : MeshComps)
		{
			Comp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			Comp.SetHiddenInGame(true);
		}

		for (ARespawnPointVolume RespawnVol : ToDisableRespawnVolumes)
		{
			RespawnVol.DisableRespawnPointVolume(this);
		}

		for (AHazePlayerCharacter Player : Game::Players)
		{
			Player.SetStickyRespawnPoint(ToEnableRespawnPoint);
			Player.AddMovementImpulse(FVector(0,0,2000.0));
		}
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		 	PlayersInside.AddUnique(Player);
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		 	PlayersInside.Remove(Player);
	}

	UFUNCTION()
	TArray<AHazePlayerCharacter> GetPlayersInside()
	{
		return PlayersInside;
	}
}