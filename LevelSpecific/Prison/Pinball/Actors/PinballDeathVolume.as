UCLASS(NotBlueprintable)
class APinballDeathVolume : ADeathVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	
	// Prediction
	private bool bSyncedPredictionInsideVolume = false;
	private bool bControlInsideVolume = false;
	private float ControlExitedVolumeTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
		{
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Network::IsGameNetworked() && Pinball::GetPaddlePlayer().HasControl())
			PaddleSidePredictedOverlap();
	}

	private void PaddleSidePredictedOverlap()
	{
		check(Network::IsGameNetworked());
		check(Pinball::GetPaddlePlayer().HasControl());
		
		auto BallPlayer = Pinball::GetBallPlayer();

		if(BallPlayer.IsPlayerRespawning())
			return;

		if(BallPlayer.IsPlayerDead())
			return;

		auto BallComp = UPinballBallComponent::Get(BallPlayer);
		if(BallComp == nullptr)
			return;

		if(EncompassesPoint(BallComp.Owner.ActorLocation, BallComp.GetRadius()))
		{
			if(!bSyncedPredictionInsideVolume)
				NetSetPredictionInsideVolume(true);
		}
		else
		{
			if(bSyncedPredictionInsideVolume)
				NetSetPredictionInsideVolume(false);
		}
	}

    UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
    void ActorBeginOverlap(AActor OtherActor) override
    {
		auto BallComp = UPinballBallComponent::Get(OtherActor);
		if(BallComp == nullptr)
			return;

		if(!Network::IsGameNetworked())
		{
			Super::ActorBeginOverlap(OtherActor);
		}
		else
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player != nullptr)
			{
				if (!IsEnabledForPlayer(Player))
					return;

				if(!bControlInsideVolume)
					SetControlSideInVolume(true);

				return;
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		// Only used in networked games
		if(!Network::IsGameNetworked())
			return;

		if(Network::IsGameNetworked() && !Pinball::GetBallPlayer().HasControl())
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		if (!IsEnabledForPlayer(Player))
			return;

		if(bControlInsideVolume)
			SetControlSideInVolume(false);
	}

	UFUNCTION(NetFunction)
	private void NetSetPredictionInsideVolume(bool bIsInside)
	{
		check(Network::IsGameNetworked());
		check(bSyncedPredictionInsideVolume != bIsInside);

		bSyncedPredictionInsideVolume = bIsInside;

		HandshakePlayerInVolumeOnBothSides();
	}

	private void SetControlSideInVolume(bool bIsInside)
	{
		check(Network::IsGameNetworked());
		check(bControlInsideVolume != bIsInside);

		bControlInsideVolume = bIsInside;

		// Save the time when we exited the volume
		if(!bControlInsideVolume)
			ControlExitedVolumeTime = Time::GameTimeSeconds;

		HandshakePlayerInVolumeOnBothSides();
	}

	private void HandshakePlayerInVolumeOnBothSides()
	{
		check(Network::IsGameNetworked());

		auto Player = Pinball::GetBallPlayer();

		if (!IsEnabledForPlayer(Player))
			return;

		// Only the ball player can check the handshake conditions
		// The paddle side is more jiterry, so false negatives can occur
		if(!Player.HasControl())
			return;

		if(Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return;

		// Since many death volumes are rather thin, we use a time window from when we exit the volume on the ball side, and consider us to still be within it
		// in that time window. This helps prevent the player from going through death volumes.
		// This window is required since the ball player can be inside a death volume, but then the paddle side decides to do a launch, and moves the player to
		// outside the death volume, and it is fully valid. In non-networked gameplay, the player can never exit a death volume.
		const float ExitTimeWindow = Network::PingOneWaySeconds;
		const bool bLocallyInsideDeathVolume = (bControlInsideVolume || Time::GetGameTimeSince(ControlExitedVolumeTime) < ExitTimeWindow);

		if(bLocallyInsideDeathVolume && bSyncedPredictionInsideVolume)
		{
			Player.KillPlayer();
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor)
	private void LogAllDefaultDeathVolumes() const
	{
		TArray<AActor> DeathVolumesActors = GetAllDefaultDeathVolumes();
		for(auto DeathVolumeActor : DeathVolumesActors)
		{
			PrintWarning(f"Death Volume {DeathVolumeActor} needs to be replaced with a PinballDeathVolume!");
		}
	}

	UFUNCTION(CallInEditor)
	private void SelectAllDefaultDeathVolumes() const
	{
		Editor::SelectActors(GetAllDefaultDeathVolumes());
	}

	private TArray<AActor> GetAllDefaultDeathVolumes() const
	{
		TArray<ADeathVolume> DeathVolumesActors = Editor::GetAllEditorWorldActorsOfClass(ADeathVolume);
		TArray<AActor> DefaultDeathVolumes;
		for(auto DeathVolumeActor : DeathVolumesActors)
		{
			auto PinballDeathVolume = Cast<APinballDeathVolume>(DeathVolumeActor);
			if(PinballDeathVolume != nullptr)
				continue;

			DefaultDeathVolumes.Add(DeathVolumeActor);
		}

		return DefaultDeathVolumes;
	}
#endif
};