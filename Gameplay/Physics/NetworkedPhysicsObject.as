enum ENetworkedPhysicsObjectControlSide
{
	Host,
	Mio,
	Zoe
}

class ANetworkedPhysicsObject : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent Mesh;
	default Mesh.SetSimulatePhysics(true);
	default Mesh.CollisionProfileName = n"PhysicsActor";

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedPosition.SyncRate = DefaultSyncRate;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere)
	ENetworkedPhysicsObjectControlSide DefaultControlSide = ENetworkedPhysicsObjectControlSide::Host;

	UPROPERTY(EditAnywhere)
	bool bSwitchControlSideWhenPlayersWithinRelevancyDistance = true;

	UPROPERTY(EditAnywhere)
	bool bIncreaseSyncRateWhenPlayersWithinRelevancyDistance = true;

	UPROPERTY(EditAnywhere)
	EHazeCrumbSyncRate DefaultSyncRate = EHazeCrumbSyncRate::Standard;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bIncreaseSyncRateWhenPlayersWithinRelevancyDistance", EditConditionHides))
	EHazeCrumbSyncRate SyncRateWhenPlayersClose = EHazeCrumbSyncRate::PlayerSynced;
	
	/* If any player is within this distance to the actor it will dynamically switch control side and/or set the sync rate to higher when player's get close */
	UPROPERTY(EditAnywhere)
	float PlayerRelevancyDistance = 500.0;

	private const bool bDebug = false;

	private AHazePlayerCharacter CurrentControlSide;
	private TPerPlayer<float> SqrDistanceToPlayers;
	private EHazeCrumbSyncRate CurrentSyncRate = DefaultSyncRate;
	private AHazePlayerCharacter DefaultControllingPlayer;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if(Mesh.StaticMesh == nullptr)
		{
			Mesh.StaticMesh = Cast<UStaticMesh>(LoadObject(nullptr, "/Game/Environment/BasicShapes/Cube.Cube"));
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		Mesh.SetSimulatePhysics(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Mesh.SetSimulatePhysics(true);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Network::IsGameNetworked())
		{
			DefaultControllingPlayer = GetDefaultControllingPlayer();
			SetControlSide(DefaultControllingPlayer);
			SyncedPosition.OverrideSyncRate(DefaultSyncRate);
			SetActorTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSwitchControlSideWhenPlayersWithinRelevancyDistance || bIncreaseSyncRateWhenPlayersWithinRelevancyDistance)
			CalculateSqrDistToPlayers();

		if(bSwitchControlSideWhenPlayersWithinRelevancyDistance)
			HandleSwitchControlSide();

		if(bIncreaseSyncRateWhenPlayersWithinRelevancyDistance)
			HandleOverrideSyncRate();

		if(!HasControl())
		{
			ActorLocation = SyncedPosition.Position.WorldLocation;
			ActorRotation = SyncedPosition.Position.WorldRotation;
		}
	}

	AHazePlayerCharacter GetDefaultControllingPlayer()
	{
		switch(DefaultControlSide)
		{
			case ENetworkedPhysicsObjectControlSide::Host:
			{
				return Network::HasWorldControl() ? Game::FirstLocalPlayer : Game::FirstLocalPlayer.OtherPlayer;
			}
			case ENetworkedPhysicsObjectControlSide::Mio:
			{
				return Game::Mio;
			}
			case ENetworkedPhysicsObjectControlSide::Zoe:
			{
				return Game::Zoe;
			}
		}
	}

	void CalculateSqrDistToPlayers()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			float SqrDist = ActorLocation.DistSquared(Player.ActorLocation);
			SqrDistanceToPlayers[Player] = SqrDist;

			if(bDebug)
			{
				float MaxSqrDist = Math::Square(PlayerRelevancyDistance);
				Debug::DrawDebugLine(Player.ActorLocation, ActorCenterLocation, SqrDist > MaxSqrDist ? FLinearColor::Red : FLinearColor::Green);
			}
		}
	}

	void HandleSwitchControlSide()
	{
		if(!HasControl())
			return;

		// If the velocity is not zero we don't want to switch control side!
		if(!Mesh.ComponentVelocity.IsNearlyZero())
			return;

		float MaxSqrDist = Math::Square(PlayerRelevancyDistance);
		bool bMioInRange = SqrDistanceToPlayers[EHazePlayer::Mio] < MaxSqrDist;
		bool bZoeInRange = SqrDistanceToPlayers[EHazePlayer::Zoe] < MaxSqrDist;

		if(!bMioInRange && !bZoeInRange)
		{
			SetControlSide(DefaultControllingPlayer);
		}
		else if(bMioInRange && bZoeInRange)
		{
			SetControlSide(SqrDistanceToPlayers[EHazePlayer::Mio] < SqrDistanceToPlayers[EHazePlayer::Zoe] ? Game::Mio : Game::Zoe);
		}
		else
		{
			SetControlSide(bMioInRange ? Game::Mio : Game::Zoe);
		}
	}

	void HandleOverrideSyncRate()
	{
		float MaxSqrDist = Math::Square(PlayerRelevancyDistance);
		bool bMioInRange = SqrDistanceToPlayers[EHazePlayer::Mio] < MaxSqrDist;
		bool bZoeInRange = SqrDistanceToPlayers[EHazePlayer::Zoe] < MaxSqrDist;
		
		EHazeCrumbSyncRate NewSyncRate;
		if(bMioInRange || bZoeInRange)
			NewSyncRate = SyncRateWhenPlayersClose;
		else
			NewSyncRate = DefaultSyncRate;

		if(NewSyncRate == CurrentSyncRate)
			return;

		SyncedPosition.OverrideSyncRate(NewSyncRate);
		CurrentSyncRate = NewSyncRate;

		if(Game::Mio.HasControl() && bDebug)
			Print(f"Set sync rate to {CurrentSyncRate} for {Name}");
	}

	void SetControlSide(AHazePlayerCharacter Player)
	{
		if(!HasControl())
			return;

		if(CurrentControlSide == Player)
			return;

		CrumbSetControlSide(Player);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbSetControlSide(AHazePlayerCharacter Player)
	{
		SetActorControlSide(Player);
		Mesh.SetSimulatePhysics(HasControl());
		CurrentControlSide = Player;

		if(Game::Mio.HasControl() && bDebug)
			Print(f"Set control side to {Player.Name} for {Name}");
	}
}