event void FOnDoubleTriggerTriggered(bool bZoeOnTrigger01);
class AGameShowArenaDoubleTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger01;
	default Trigger01.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default Trigger01.BoxExtent = FVector(150, 150, 150);
	default Trigger01.LineThickness = 6;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Trigger02;
	default Trigger02.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default Trigger02.BoxExtent = FVector(150, 150, 150);
	default Trigger02.LineThickness = 6;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY()
	FOnDoubleTriggerTriggered OnDoubleTriggerTriggered;

	UPROPERTY(EditInstanceOnly)
	bool bStartDisabled = true;

	UPROPERTY(EditInstanceOnly)
	bool bShouldDisableAfterTrigger = true;

	// Spawn Transform Relative to Actor
	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	FTransform Trigger01RespawnRelativeTransform;

	// Spawn Transform Relative to Actor
	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	FTransform Trigger02RespawnRelativeTransform;

	TPerPlayer<bool> PlayersInTrigger01;
	TPerPlayer<bool> PlayersInTrigger02;

	FInstigator StartDisabled;
	FInstigator DisableAfterTrigger;

	TPerPlayer<FRespawnLocation> StoredSpawns;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bStartDisabled)
			AddActorDisable(StartDisabled);

		Trigger01.OnComponentBeginOverlap.AddUFunction(this, n"OnTrigger01Overlap");
		Trigger02.OnComponentBeginOverlap.AddUFunction(this, n"OnTrigger02Overlap");
		Trigger01.OnComponentEndOverlap.AddUFunction(this, n"OnTrigger01EndOverlap");
		Trigger02.OnComponentEndOverlap.AddUFunction(this, n"OnTrigger02EndOverlap");
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		CreatePlayerEditorVisualizer(Root, EHazePlayer::Mio, Trigger01RespawnRelativeTransform);
		CreatePlayerEditorVisualizer(Root, EHazePlayer::Zoe, Trigger02RespawnRelativeTransform);
	}

	UFUNCTION(CallInEditor)
	void SnapSpawnsToTriggers()
	{
		Trigger01RespawnRelativeTransform = Trigger01.RelativeTransform;
		Trigger01RespawnRelativeTransform.Location = Trigger01.RelativeLocation + FVector::DownVector * 100;
		Trigger02RespawnRelativeTransform = Trigger02.RelativeTransform;
		Trigger02RespawnRelativeTransform.Location = Trigger02.RelativeLocation + FVector::DownVector * 100;
		Editor::RerunConstructionScript(this);
	}
	UFUNCTION(CallInEditor)
	void SnapSpawnsToGround()
	{
		TraceTransformToGround(Trigger01RespawnRelativeTransform);
		TraceTransformToGround(Trigger02RespawnRelativeTransform);
	}

	void TraceTransformToGround(FTransform& InOutRelativeTransform)
	{
		FTransform WorldTransform = InOutRelativeTransform * Root.WorldTransform;

		auto GroundTrace = Trace::InitProfile(n"PlayerCharacter");
		GroundTrace.UseCapsuleShape(30.0, 88.0, ActorQuat);

		FHitResultArray Hits = GroundTrace.QueryTraceMulti(
			WorldTransform.Location + ActorUpVector * 150.0,
			WorldTransform.Location - ActorUpVector * 150.0, );

		for (FHitResult Hit : Hits)
		{
			if (!Hit.bBlockingHit)
				continue;
			if (Hit.bStartPenetrating)
				continue;

			InOutRelativeTransform.Location = Root.WorldTransform.InverseTransformPosition(Hit.ImpactPoint);
			break;
		}
	}
#endif
	UFUNCTION()
	private void OnTrigger01Overlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
							const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInTrigger01[Player] = true;
		HandlePlayerEnterTrigger();
	}

	UFUNCTION()
	private void OnTrigger02Overlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
							const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInTrigger02[Player] = true;
		HandlePlayerEnterTrigger();
	}

	UFUNCTION()
	private void OnTrigger01EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInTrigger01[Player] = false;
	}

	UFUNCTION()
	private void OnTrigger02EndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
							   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayersInTrigger02[Player] = false;
	}

	UFUNCTION()
	void TeleportToDoubleTrigger(AHazePlayerCharacter Player)
	{
		FVector WorldLocation = StoredSpawns[Player].RespawnRelativeTo.WorldTransform.TransformPositionNoScale(StoredSpawns[Player].RespawnTransform.Location);
		FRotator WorldRotation = StoredSpawns[Player].RespawnRelativeTo.WorldTransform.TransformRotation(StoredSpawns[Player].RespawnTransform.Rotator());
		Player.TeleportActor(WorldLocation, WorldRotation, this);
	}

	AHazePlayerCharacter GetPlayerInTrigger(TPerPlayer<bool> PlayersInTrigger)
	{
		if (PlayersInTrigger[Game::Mio])
			return Game::Mio;
		else if (PlayersInTrigger[Game::Zoe])
			return Game::Zoe;
		else
			return nullptr;
	}

	bool ArePlayersInBothTriggers()
	{
		return (PlayersInTrigger01[Game::Mio] != PlayersInTrigger01[Game::Zoe]) && (PlayersInTrigger02[Game::Mio] != PlayersInTrigger02[Game::Zoe]);
	}

	void HandlePlayerEnterTrigger()
	{
		if (ArePlayersInBothTriggers())
		{
			auto Player1 = GetPlayerInTrigger(PlayersInTrigger01);
			auto Player2 = GetPlayerInTrigger(PlayersInTrigger02);
			StoredSpawns[Player1].RespawnTransform = Trigger01RespawnRelativeTransform;
			StoredSpawns[Player1].RespawnRelativeTo = Root;

			StoredSpawns[Player2].RespawnTransform = Trigger02RespawnRelativeTransform;
			StoredSpawns[Player2].RespawnRelativeTo = Root;

			Game::Mio.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"));
			Game::Zoe.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"));
			bool bZoeOnTrigger01 = Player1.IsZoe();
			OnDoubleTriggerTriggered.Broadcast(bZoeOnTrigger01);
			if (bShouldDisableAfterTrigger)
				AddActorDisable(DisableAfterTrigger);
		}
	}

	UFUNCTION()
	void ClearRespawnOverrides()
	{
		Game::Mio.ClearRespawnPointOverride(this);
		Game::Zoe.ClearRespawnPointOverride(this);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		OutLocation.RespawnTransform = StoredSpawns[Player].RespawnTransform;
		OutLocation.RespawnRelativeTo = StoredSpawns[Player].RespawnRelativeTo;
		return true;
	}
}