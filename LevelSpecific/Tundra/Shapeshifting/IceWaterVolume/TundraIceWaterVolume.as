class ATundraIceSwimmingVolume : ASwimmingVolume
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	TPerPlayer<float> PlayersTimeOfEnter;
	default PlayersTimeOfEnter[EHazePlayer::Mio] = -1.0;
	default PlayersTimeOfEnter[EHazePlayer::Zoe] = -1.0;

	TPerPlayer<float> PlayerKillTime;
	default PlayerKillTime[EHazePlayer::Mio] = 0.15;
	default PlayerKillTime[EHazePlayer::Zoe] = 0.15;

	const float DefaultKillTime = 0.15;
	const float ShapeshiftKillTime = 0.3;

	TArray<AHazePlayerCharacter> Players;

	UPROPERTY(EditInstanceOnly, Category = "DeathEffect")
	TSubclassOf<UDeathEffect> SwimVolumeDeatheffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Players = Game::Players;
	}

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		Super::ActorBeginOverlap(OtherActor);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			if(Player.HasControl())
			{
				auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
				if(Player.IsMio())
				{
					ShapeshiftComp.OnChangeShape.AddUFunction(this, n"CheckInDangerOnShapeshift");
				}
				
				if(!Player.IsMio() || (Player.IsMio() && ShapeshiftComp.CurrentShapeType != ETundraShapeshiftShape::Small))
				{
					SetPlayerInDanger(Player, true, false);
				}
			}

			if(!Player.IsSelectedBy(UsableByPlayer))
				return;

				
			UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player).SwimmingVolumeEntered(this, ConvertSwimmingActiveState(SwimmingState), StatePriority);
		}
	}

	UFUNCTION()
	private void CheckInDangerOnShapeshift(AHazePlayerCharacter Player, ETundraShapeshiftShape NewShape)
	{
		bool bInDanger = NewShape != ETundraShapeshiftShape::Small;
		SetPlayerInDanger(Player, bInDanger, true);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		Super::ActorEndOverlap(OtherActor);

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			if(Player.HasControl())
			{
				auto ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
				if(Player.IsMio())
					ShapeshiftComp.OnChangeShape.Unbind(this, n"CheckInDangerOnShapeshift");
				
				SetPlayerInDanger(Player, false, false);
			}

			UTundraPlayerOtterSwimmingComponent::GetOrCreate(Player).SwimmingVolumeExited(this);
		}
	}

	void SetPlayerInDanger(AHazePlayerCharacter Player, bool bInDanger, bool bOnShapeshift)
	{
		if(bInDanger)
		{
			PlayersTimeOfEnter[Player] = Time::GetGameTimeSeconds();
			PlayerKillTime[Player] = bOnShapeshift ? ShapeshiftKillTime : DefaultKillTime;
			SetActorTickEnabled(true);
		}
		else
		{
			PlayersTimeOfEnter[Player] = -1.0;
			SetActorTickEnabled(PlayersTimeOfEnter[Player.OtherPlayer] > 0.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto Player : Players)
		{
			float TimeOfEnter = PlayersTimeOfEnter[Player];
			if(TimeOfEnter < 0.0)
				continue;

			if(Time::GetGameTimeSeconds() - TimeOfEnter < PlayerKillTime[Player])
				continue;

			Player.KillPlayer(DeathEffect = SwimVolumeDeatheffect);
		}
	}

	ETundraPlayerOtterSwimmingActiveState ConvertSwimmingActiveState(EPlayerSwimmingActiveState State)
	{
		if(State == EPlayerSwimmingActiveState::Active)
			return ETundraPlayerOtterSwimmingActiveState::Active;
		else if(State == EPlayerSwimmingActiveState::Inactive)
			return ETundraPlayerOtterSwimmingActiveState::Inactive;
		else
			devError("Forgot to add case!");

		return ETundraPlayerOtterSwimmingActiveState::Inactive;
	}
}