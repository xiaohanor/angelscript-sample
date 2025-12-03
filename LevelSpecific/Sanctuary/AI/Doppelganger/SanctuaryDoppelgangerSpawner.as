class ASanctuaryDoppelgangerSpawner : AHazeActorSpawnerBase
{
	UPROPERTY(DefaultComponent)
	UHazeActorSpawnPatternWave DoppelPattern;
	default DoppelPattern.WaveSize = 2;

	UPROPERTY(EditAnywhere)
	AScenepointActor DoppelPos;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	TArray<FVector> CloneLocations;

	int DoppelCount = 0;
	TArray<FVector> FinalCloneLocations;
	FRotator FinalCloneRotation;
	AHazePlayerCharacter ClonedPlayer;
	bool bHasHiddenIndicators = false;

	UFUNCTION(DevFunction)
	void DoppelTime()
	{
		if (SpawnerComp.SpawnedActorsTeam != nullptr)
			return; // We've already doppeled

		if (DoppelPos == nullptr)
		{
			devError("Doppelganger spawn with no DoppelPos to base the scenario upon! /n" + 
				     "Place a scenepoint actor at the exact same position as the spawner /n" + 
				     "in the duplicated part of the level and set that as DoppelPos on the spawner.");
			return;
		} 

		if (!DoppelPattern.SpawnClass.IsValid())
		{
			devError("Doppelganger spawn with no doppelganger spawn class!");
			return;
		}

		HideIndicators();	
		ActivateSpawner();
	}

	UFUNCTION(DevFunction)
	void MultiCloneMio()
	{
		MultiClone(Game::Mio);
	}

	UFUNCTION(DevFunction)
	void MultiCloneZoe()
	{
		MultiClone(Game::Zoe);
	}

	void MultiClone(AHazePlayerCharacter Player)
	{
		if (SpawnerComp.SpawnedActorsTeam != nullptr)
			return; // We've already doppeled

		if (!DoppelPattern.SpawnClass.IsValid())
		{
			devError("Doppelganger multiclone with no doppelganger spawn class!");
			return;
		}

		FTransform CloneTransform = FTransform(ActorRotation, Player.ActorLocation);
		TArray<FVector> CloneLocs; 
		// Add player current location
		CloneLocs.Add(Player.ActorLocation);

		// Add set clone locations relative to player location but spawner rotation
		for (FVector Offset : CloneLocations)
		{
			CloneLocs.Add(CloneTransform.TransformPosition(Offset));
		}

		// Fill out with locations to the left and right until we have enough for the player and all clones
		for (int n = CloneLocs.Num(); n < DoppelPattern.WaveSize + 1; n++)
		{
			float Side = ((n % 2) * 2) - 1.0;
			float Dist = Math::IntegerDivisionTrunc((n + 1), 2) * 100.f;
			CloneLocs.Add(CloneTransform.TransformPosition(ActorRightVector * Side * Dist));
		}

		// Shuffle player
		CloneLocs.Shuffle();
		Player.TeleportActor(CloneLocs.Last(), Player.ActorRotation, this);
		CloneLocs.RemoveAtSwap(CloneLocs.Num() - 1);
		HideIndicators();

		// Let the cloning begin
		CrumbMultiClonePositions(Player, Player.ActorRotation, CloneLocs);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbMultiClonePositions(AHazePlayerCharacter Player, FRotator Rotation, TArray<FVector> Locations)
	{
		ClonedPlayer = Player;
		FinalCloneRotation = Rotation;
		FinalCloneLocations = Locations;
		SpawnerComp.OnPostSpawn.Unbind(this, n"OnPostSpawn");
		SpawnerComp.OnPostSpawn.AddUFunction(this, n"OnPostClone");
		ActivateSpawner();
	}

	UFUNCTION(DevFunction)
	void HabschMove()
	{
		SetWeirdMovement(EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	void SetWeirdMovement(EHazeSelectPlayer MimickedPlayer)
	{
		if (SpawnerComp.SpawnedActorsTeam == nullptr)
			return; // Haven't started doppling yet!

		TArray<AHazeActor> DoppelMembers = SpawnerComp.SpawnedActorsTeam.GetMembers();
		for (AHazeActor Doppelganger : DoppelMembers)
		{
			if (Doppelganger == nullptr)
				continue;
			USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(Doppelganger);
			if (DoppelComp == nullptr)
				continue;
			if (!DoppelComp.MimicTarget.IsSelectedBy(MimickedPlayer))
				continue;
			DoppelComp.MimicState = EDoppelgangerMimicState::MimicAppearance;
		}
	}

	UFUNCTION(DevFunction)
	void RandomMove()
	{
		SetRandomMove(EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	void SetRandomMove(EHazeSelectPlayer MimickedPlayer)
	{
		if (SpawnerComp.SpawnedActorsTeam == nullptr)
			return; // Haven't started doppling yet!

		TArray<AHazeActor> DoppelMembers = SpawnerComp.SpawnedActorsTeam.GetMembers();
		for (AHazeActor Doppelganger : DoppelMembers)
		{
			if (Doppelganger == nullptr)
				continue;
			USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(Doppelganger);
			if (DoppelComp == nullptr) 
				continue;
			if (!DoppelComp.MimicTarget.IsSelectedBy(MimickedPlayer))
				continue;
			DoppelComp.MimicState = EDoppelgangerMimicState::RandomMove;
		}
	}

	UFUNCTION(DevFunction)
	void ReturnToDoppel()
	{
		SetReturnToFullMimic(EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	void SetReturnToFullMimic(EHazeSelectPlayer MimickedPlayer)
	{
		if (SpawnerComp.SpawnedActorsTeam == nullptr)
			return; // Haven't started doppling yet!

		TArray<AHazeActor> DoppelMembers = SpawnerComp.SpawnedActorsTeam.GetMembers();
		for (AHazeActor Doppelganger : DoppelMembers)
		{
			if (Doppelganger == nullptr)
				continue;
			USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(Doppelganger);
			if (DoppelComp == nullptr) 
				continue;
			if (!DoppelComp.MimicTarget.IsSelectedBy(MimickedPlayer))
				continue;
			if (DoppelComp.MimicState == EDoppelgangerMimicState::FullMimic)
				continue; // Already mimicking
			DoppelComp.MimicState = EDoppelgangerMimicState::WantsFullMimic;
		}
	}

	UFUNCTION(DevFunction)
	void Reveal()
	{
		SetReveal(EHazeSelectPlayer::Both);
	}

	UFUNCTION()
	void SetReveal(EHazeSelectPlayer MimickedPlayer)
	{
		if (SpawnerComp.SpawnedActorsTeam == nullptr)
			return; // Haven't started doppling yet!

		TArray<AHazeActor> DoppelMembers = SpawnerComp.SpawnedActorsTeam.GetMembers();
		for (AHazeActor Doppelganger : DoppelMembers)
		{
			if (Doppelganger == nullptr)
				continue;
			USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(Doppelganger);
			if (DoppelComp == nullptr)
				continue;
			if (!DoppelComp.MimicTarget.IsSelectedBy(MimickedPlayer))
				continue;
			DoppelComp.MimicState = EDoppelgangerMimicState::Reveal;
		}

		ShowIndicators();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SpawnerComp.OnPostSpawn.AddUFunction(this, n"OnPostSpawn");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		ShowIndicators();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPostSpawn(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner != SpawnerComp)
			return;
		USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(SpawnedActor);
		if (DoppelComp == nullptr)
			return;

		FTransform MimicTransform = ActorTransform.Inverse() * DoppelPos.ActorTransform;		
		DoppelCount++;
		if (DoppelCount == 1)
		{
			// Mio remains where she is, Zoe is teleported
			AHazePlayerCharacter MimickedPlayer = Game::Zoe;
			FTransform MimicPos = MimickedPlayer.ActorTransform;
			FRotator ViewRotation = MimickedPlayer.ViewRotation;
			FTransform TeleportPos = MimicPos * MimicTransform;
			MimickedPlayer.TeleportActor(TeleportPos.Location, TeleportPos.Rotator(), this);
			MimickedPlayer.SnapCameraAtEndOfFrame(MimicTransform.TransformRotation(FQuat(ViewRotation)).Rotator(), EHazeCameraSnapType::World);

			// Replace Zoe by doppelganger near Mio
			DoppelComp.MimicTarget = MimickedPlayer;
			DoppelComp.DoppelTransform = MimicPos; 
			DoppelComp.MimicState = EDoppelgangerMimicState::FullMimic;
			SpawnedActor.TeleportActor(MimicPos.Location, MimicPos.Rotator(), this);

			DoppelComp.MimicTargetInverseTransform = DoppelComp.MimicTarget.ActorTransform.Inverse();
			DoppelComp.MimicTransform = MimicPos;
		}
		else
		{
			// Second doppelganger replaces Mio near Zoe
			AHazePlayerCharacter MimickedPlayer = Game::Mio;
			FTransform MimicPos = MimickedPlayer.ActorTransform * MimicTransform;
			DoppelComp.MimicTarget = MimickedPlayer;
			DoppelComp.DoppelTransform = MimicPos;
			DoppelComp.MimicState = EDoppelgangerMimicState::FullMimic;
			SpawnedActor.TeleportActor(MimicPos.Location, MimicPos.Rotator(), this);

			DoppelComp.MimicTargetInverseTransform = DoppelComp.MimicTarget.ActorTransform.Inverse();
			DoppelComp.MimicTransform = MimicPos;

			// There should be no further doppelgangers
			DeactivateSpawner();
		}
	}

	UFUNCTION()
	private void OnPostClone(AHazeActor SpawnedActor, UHazeActorSpawnerComponent Spawner, UHazeActorSpawnPattern SpawningPattern)
	{
		if (Spawner != SpawnerComp)
			return;
		USanctuaryDoppelgangerComponent DoppelComp = USanctuaryDoppelgangerComponent::Get(SpawnedActor);
		if (DoppelComp == nullptr)
			return;
		
		DoppelComp.MimicTarget = ClonedPlayer;
		DoppelComp.DoppelTransform = FTransform(FinalCloneRotation, FinalCloneLocations.Last());
		DoppelComp.MimicState = EDoppelgangerMimicState::FullMimic;
		SpawnedActor.TeleportActor(DoppelComp.DoppelTransform.Location, DoppelComp.DoppelTransform.Rotator(), this);

		DoppelComp.MimicTargetInverseTransform = DoppelComp.MimicTarget.ActorTransform.Inverse();
		DoppelComp.MimicTransform = DoppelComp.DoppelTransform;

		FinalCloneLocations.RemoveAtSwap(FinalCloneLocations.Num() - 1);
	}

	void HideIndicators()
	{
		if (!bHasHiddenIndicators)
		{
			Outline::ApplyNoOutlineOnActor(Game::Zoe, Game::Mio, this, EInstigatePriority::Normal); 
			Outline::ApplyNoOutlineOnActor(Game::Mio, Game::Zoe, this, EInstigatePriority::Normal); 
			Game::Zoe.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
			Game::Mio.BlockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
			bHasHiddenIndicators = true;
		}
	}

	void ShowIndicators()
	{
		if (bHasHiddenIndicators)
		{
			Outline::ClearOutlineOnActor(Game::Zoe, Game::Mio, this); 
			Outline::ClearOutlineOnActor(Game::Mio, Game::Zoe, this); 
			Game::Zoe.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
			Game::Mio.UnblockCapabilities(CapabilityTags::OtherPlayerIndicator, this);
			bHasHiddenIndicators = false;
		}
	}
}
