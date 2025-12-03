namespace Centipede
{
	FVector GetPlayerHeadMovementInput(AHazePlayerCharacter Player, FVector2D RawInput, bool bDebugDraw = false)
	{
		FVector ForwardVector;
		FVector RightVector;

		FVector UpVector = Player.MovementWorldUp;

		// Floor
		if(Math::Abs(UpVector.Z) > 0.5)
		{
			RightVector = Player.GetControlRotation().RightVector.VectorPlaneProject(UpVector).GetSafeNormal();
			ForwardVector = RightVector.CrossProduct(UpVector).GetSafeNormal();
		}
		else
		{
			ForwardVector = FVector::UpVector;
			RightVector = UpVector.CrossProduct(FVector::UpVector).GetSafeNormal();
		}

		FVector MoveInput = ForwardVector * RawInput.X + RightVector * RawInput.Y;

		if (bDebugDraw)
			Debug::DrawDebugDirectionArrow(Player.ActorCenterLocation, MoveInput, MoveInput.Size() * 1000, 5, FLinearColor::Green);

		return MoveInput;
	}

	// Calls to this MUST be networked
	UFUNCTION(BlueprintCallable, Category = "Sanctuary|Centipede", Meta = (DefaultToSelf = Instigator))
	ACentipede SpawnCentipede(TSubclassOf<ACentipede> CentipedeClass, UObject Instigator)
	{
		if (!devEnsure(Instigator != nullptr, "Must use a valid instigator when spawning centipede!"))
			return nullptr;

		ACentipede Centipede = SpawnActor(CentipedeClass, bDeferredSpawn = true);
		Centipede.MakeNetworked(Instigator);
		FinishSpawningActor(Centipede);

		return Centipede;
	}

	UFUNCTION(BlueprintCallable, Category = "Sanctuary|Centipede")
	void MountPlayersOnCentipede(ACentipede& Centipede)
	{
		for (auto Player : Game::Players)
		{
			UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
			if (CentipedeComponent != nullptr)
				CentipedeComponent.MountCentipede(Centipede);
		}
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Clear Centipede if Active", Category = "Sanctuary|Centipede")
	void CentipedeClearCentipedeIfActive()
	{
		for (auto Player : Game::Players)
		{
			UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
			if (CentipedeComponent != nullptr)
				CentipedeComponent.ClearCentipede();
		}
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Centipede Set Allow Respawn", Category = "Sanctuary|Centipede")
	void CentipedeSetAllowRespawn(bool bAllowRespawn)
	{

		UPlayerCentipedeComponent MioCentipedeComp = UPlayerCentipedeComponent::Get(Game::Mio);
		UPlayerCentipedeComponent ZoeCentipedeComp = UPlayerCentipedeComponent::Get(Game::Zoe);

		if (MioCentipedeComp != nullptr)
		{
			bool bWasBlocked = !MioCentipedeComp.bAllowRespawn;
			MioCentipedeComp.bAllowRespawn = bAllowRespawn;
			if (!bAllowRespawn)
			{
				UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Game::Mio, true, MioCentipedeComp);
				Game::Mio.BlockCapabilities(n"Respawn", MioCentipedeComp);
			}
			else if (bWasBlocked)
			{
				UPlayerHealthSettings::ClearGameOverWhenBothPlayersDead(Game::Mio, MioCentipedeComp);
				Game::Mio.UnblockCapabilities(n"Respawn", MioCentipedeComp);
			}
		}

		if (ZoeCentipedeComp != nullptr)
		{
			bool bWasBlocked = !ZoeCentipedeComp.bAllowRespawn;
			ZoeCentipedeComp.bAllowRespawn = bAllowRespawn;
			if (!bAllowRespawn)
			{
				UPlayerHealthSettings::SetGameOverWhenBothPlayersDead(Game::Zoe, true, ZoeCentipedeComp);
				Game::Zoe.BlockCapabilities(n"Respawn", MioCentipedeComp);
			}
			else if (bWasBlocked)
			{
				UPlayerHealthSettings::ClearGameOverWhenBothPlayersDead(Game::Zoe, ZoeCentipedeComp);
				Game::Zoe.UnblockCapabilities(n"Respawn", MioCentipedeComp);
			}
		}
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Maybe Open Draggable Gates", Category = "Sanctuary|Centipede")
	void BP_MaybeOpenDraggableGates(bool bSlopeCheckpoint, bool bRiverCheckpoint, bool bNaturalProgression)
	{
		if (bNaturalProgression)
			return;

		USanctuaryUglyProgressionPlayerComponent UglyComp = USanctuaryUglyProgressionPlayerComponent::GetOrCreate(Game::Mio);
		UglyComp.bPassedSlopeGateCheckpoint = bSlopeCheckpoint;
		UglyComp.bPassedMoleGateCheckpoint = bRiverCheckpoint;
	}

	UFUNCTION(BlueprintCallable, DisplayName = "Maybe Open Blood Gate", Category = "Sanctuary|Below")
	void BP_MaybeOpenBloodGate(bool bNaturalProgression)
	{
		if (bNaturalProgression)
			return;

		USanctuaryUglyProgressionPlayerComponent UglyComp = USanctuaryUglyProgressionPlayerComponent::GetOrCreate(Game::Mio);
		UglyComp.bPassedBloodGateCheckpoint = true;
	}

	FVector ConstrainPlayerLocationToBody(AHazePlayerCharacter Player, FVector Location, float MaxDistance)
	{
		FVector PlayerToOtherPlayer = Player.OtherPlayer.ActorLocation - Location;
		float Delta = PlayerToOtherPlayer.Size() - MaxDistance;
		if (Delta > 0)
		{
			return Location + PlayerToOtherPlayer.GetSafeNormal() * Delta;
		}
		
		return FVector::ZeroVector;
	}

	void ConstrainAirVelocityToBody(FVector PlayerLocation, AHazePlayerCharacter OtherPlayer, float MaxDistance, float DeltaTime, FVector& OutVelocity)
	{
		// Nvm if player aims towards other player
		FVector PlayerToOtherPlayer = (OtherPlayer.ActorLocation - PlayerLocation).GetSafeNormal();

		// Get distance between heads and redirect velocity if too high
		FVector NextPlayerLocation = PlayerLocation + OutVelocity * DeltaTime;
		float DistanceBetweenPlayers = OtherPlayer.ActorLocation.Distance(NextPlayerLocation);
		if (DistanceBetweenPlayers >= MaxDistance)
		{
			// Make up for any slack we give
			float DeltaLength = DistanceBetweenPlayers - MaxDistance;

			FVector MoveDelta = OutVelocity * DeltaTime;
			FVector DeltaCorrection = PlayerToOtherPlayer * DeltaLength;

			float MaxSpeed = MoveDelta.Size() + OtherPlayer.ActorVelocity.Size();
			MoveDelta = (MoveDelta + DeltaCorrection).GetClampedToMaxSize(MaxSpeed);

			// Convert back to velocity
			OutVelocity = MoveDelta / DeltaTime;

			// Debug::DrawDebugDirectionArrow(Player.ActorLocation, DeltaCorrection, DeltaLength * 10, 10, FLinearColor::Green, 10, 1);
		}
	}

	FVector GetPredictedLocation(FVector PlayerLocation, const FHazeSyncedActorPosition& SyncedPosition, float LatestCrumbTrailTime, float DeltaTime)
	{
		// Get predicted location
		// const float PredictionTime = (Time::OtherSideCrumbTrailSendTimePrediction - LatestCrumbTrailTime);
		// FVector PredictedLocation = SyncedPosition.WorldLocation + SyncedPosition.WorldVelocity * PredictionTime * DeltaTime;

		// // Smooth prediction
		// FVector MoveDelta = PredictedLocation - PlayerLocation;
		// PredictedLocation = Math::VInterpTo(PlayerLocation, PredictedLocation, DeltaTime, ((MoveDelta * DeltaTime).Size() / (Time::EstimatedCrumbReachedDelay * 2)));

		const float PredictionTime = (Time::OtherSideCrumbTrailSendTimePrediction - LatestCrumbTrailTime);// + Network::PingOneWaySeconds;
		FVector PredictedLocation = SyncedPosition.WorldLocation + SyncedPosition.WorldVelocity * PredictionTime;

		// Smooth prediction
		PredictedLocation = Math::VInterpTo(PlayerLocation, PredictedLocation, DeltaTime, 1.0 / Math::Max(DeltaTime, Network::PingOneWaySeconds));

		return PredictedLocation;
	}
}

class USanctuaryUglyProgressionPlayerComponent : UActorComponent
{
	bool bPassedSlopeGateCheckpoint = false;
	bool bPassedMoleGateCheckpoint = false;
	bool bPassedBloodGateCheckpoint = false;
};