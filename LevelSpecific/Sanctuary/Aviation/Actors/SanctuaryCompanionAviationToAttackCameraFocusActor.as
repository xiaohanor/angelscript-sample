class ASanctuaryCompanionAviationToAttackCameraFocusActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent RootComp;
	default RootComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncedPosition;
	default SyncedPosition.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::TransformOnly;
	default SyncedPosition.SyncRate = EHazeCrumbSyncRate::High;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	USimpleMovementData Movement;

	UPROPERTY(EditAnywhere)
	EHazePlayer NetController;

	private bool bUseDesiredLocation = false;
	private FVector ControlDesiredLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (NetController == EHazePlayer::Mio)
			SetActorControlSide(Game::Mio);
		if (NetController == EHazePlayer::Zoe)
			SetActorControlSide(Game::Zoe);
	
		Movement = MovementComponent.SetupSimpleMovementData();
	};

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateLocation();
	}

	void UpdateLocation()
	{
		if (HasControl())
		{
			if (MovementComponent.PrepareMove(Movement))
			{
				FVector TargetLocation = bUseDesiredLocation ? ControlDesiredLocation : GetPlayerLocation();
				FVector Delta = TargetLocation - ActorLocation;
				if (Delta.Size() > KINDA_SMALL_NUMBER)
					Movement.AddDelta(Delta);
				MovementComponent.ApplyMove(Movement);
				bUseDesiredLocation = false;
			}
		}
		else
		{
			auto& Position = SyncedPosition.Position;
			SetActorLocationAndRotation(
				Position.WorldLocation,
				Position.WorldRotation
			);
		}
	}

	private FVector GetPlayerLocation()
	{
		if (NetController == EHazePlayer::Zoe)
			return Game::Zoe.ActorLocation;
		return Game::Mio.ActorLocation;
	}

	void SetControlDesiredLocation(FVector DesiredLocation)
	{
		ControlDesiredLocation = DesiredLocation;
		bUseDesiredLocation = true;
	}
};