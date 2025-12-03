class AStoneBeastInverseDeathVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.CollisionProfileName = CollisionProfile::TriggerOnlyPlayer;
	default SphereComp.SphereRadius = TrackingDistance;
	default SphereComp.LineThickness = 50;
	default SphereComp.ShapeColor = FColor::Turquoise;

	UPROPERTY(EditAnywhere)
	float TrackingDistance = 8000;
	UPROPERTY(EditAnywhere)
	float KillDistance = 4000;

	TPerPlayer<bool> TrackedPlayers;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	float KillDistSq;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SphereComp.SphereRadius = TrackingDistance;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, KillDistance, 16, FLinearColor::Red, 50);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlapBegin");
		SphereComp.OnComponentEndOverlap.AddUFunction(this, n"OnOverlapEnd");
		KillDistSq = KillDistance * KillDistance;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (auto Player : Game::Players)
		{
			if (!TrackedPlayers[Player])
				continue;

			float MeshDistSq = Player.Mesh.WorldLocation.DistSquared(ActorLocation);
			float PlayerDistSq = Player.GetSquaredDistanceTo(this);

			if (PlayerDistSq >= KillDistSq || MeshDistSq >= KillDistSq)
				Player.KillPlayer();
		}
	}

	UFUNCTION()
	private void OnOverlapBegin(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                            UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                            const FHitResult&in SweepResult)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		TrackedPlayers[Player] = true;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	private void OnOverlapEnd(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                          UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (IsActorDisabled())
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			if (Player == nullptr)
				return;
			
			TrackedPlayers[Player] = false;
			if (!TrackedPlayers[Player.OtherPlayer])
				SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void DisableDeathVolumeByInstigator(FInstigator Instigator)
	{
		AddActorDisable(Instigator);
		TrackedPlayers[Game::Mio] = false;
		TrackedPlayers[Game::Zoe] = false;
	}

	UFUNCTION()
	void EnableDeathVolumeByInstigator(FInstigator Instigator)
	{
		RemoveActorDisable(Instigator);
	}
};