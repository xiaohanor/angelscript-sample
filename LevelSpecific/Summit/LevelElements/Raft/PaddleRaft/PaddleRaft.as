enum ERaftPaddleSide
{
	None,
	Left,
	Right
}

struct FPaddleRaftPaddleData
{
	ERaftPaddleSide Side;
	float RotationSpeed;
	float ForwardSpeed;
	float TimeLastPaddled;
}

UCLASS(Abstract)
class APaddleRaft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USummitRaftRootComponent RaftRoot;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CollisionCapsule;
	default CollisionCapsule.SetCollisionProfileName(n"Vehicle");
	default CollisionCapsule.SetCollisionObjectType(ECollisionChannel::ECC_Vehicle);
	// default CollisionCapsule.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default CollisionCapsule.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Ignore);
	default CollisionCapsule.SetCollisionResponseToChannel(SummitRaft::RaftCollisionChannel, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilityClasses.Add(UPaddleRaftMovementCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UPaddleRaftCameraCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UPaddleRaftCollisionCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncPosComp;
	default SyncPosComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncPosComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	USceneComponent VehicleOffsetRoot;

	UPROPERTY(DefaultComponent, Attach = VehicleOffsetRoot)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USceneComponent MioAttachPoint;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USceneComponent ZoeAttachPoint;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UStaticMeshComponent RaftMesh;
	default RaftMesh.RelativeLocation = FVector(0, 0, -30);

	UPROPERTY(DefaultComponent)
	USpringArmCamera RaftCamera;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.bAllowUsingBoxCollisionShape = true;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeOffsetComponent RaftFront;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	UHazeOffsetComponent RaftBack;

	UPROPERTY(DefaultComponent)
	UDynamicWaterEffectDecalComponent WaterWaveEffectComponent;

	TPerPlayer<FPaddleRaftPaddleData> PlayerPaddleData;
	TPerPlayer<bool> PaddlingPlayers;

	float YawSpeed;
	FHazeAcceleratedFloat AccRoll;

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	URaftWaterSampleComponent FLWaterSampleComp;
	default FLWaterSampleComp.RelativeLocation = FVector(210, -40, 0);

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	URaftWaterSampleComponent FRWaterSampleComp;
	default FRWaterSampleComp.RelativeLocation = FVector(210, 40, 0);

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	URaftWaterSampleComponent BLWaterSampleComp;
	default BLWaterSampleComp.RelativeLocation = FVector(-250, -40, 0);

	UPROPERTY(DefaultComponent, Attach = RaftRoot)
	URaftWaterSampleComponent BRWaterSampleComp;
	default BRWaterSampleComp.RelativeLocation = FVector(-250, 40, 0);

	TArray<URaftWaterSampleComponent> SampleComponents;

	FSplinePosition SplinePos;

	TPerPlayer<USummitRaftPlayerStaggerComponent> StaggerComps;

	bool bHasStarted = false;

	TArray<APaddleRaftPushingVolumeBase> OverlappedPushingVolumes;

	UPROPERTY(EditAnywhere)
	ASplineActor WaterSplineActor;

	UPROPERTY(EditDefaultsOnly)
	TArray<UStaticMesh> BrokenMeshes;

	int CurrentBrokenStage = 0;

	TOptional<FSummitRaftHitStaggerData> QueuedStaggerData;

	bool bHasBlockedCapabilities = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		MovementComponent.SetupShapeComponent(CollisionCapsule);

		SampleComponents.SetNum(4);
		SampleComponents[0] = FLWaterSampleComp;
		SampleComponents[1] = FRWaterSampleComp;
		SampleComponents[2] = BLWaterSampleComp;
		SampleComponents[3] = BRWaterSampleComp;
	}

	UFUNCTION(CrumbFunction)
	void CrumbTakeDamage()
	{
		int PrevBrokenStage = CurrentBrokenStage;
		CurrentBrokenStage++;
		CurrentBrokenStage = Math::Clamp(CurrentBrokenStage, 0, 2);
		if (CurrentBrokenStage != PrevBrokenStage)
		{
			UPaddleRaftEventHandler::Trigger_OnRaftDamaged(this);
			RaftMesh.StaticMesh = BrokenMeshes[CurrentBrokenStage - 1];
		}
	}

	bool CheckPlayersPaddlingSameSide() const
	{
		auto MioData = PlayerPaddleData[Game::Mio];
		auto ZoeData = PlayerPaddleData[Game::Zoe];
		if (MioData.Side == ERaftPaddleSide::None && ZoeData.Side == ERaftPaddleSide::None)
			return false;

		bool bSameSide = MioData.Side == ZoeData.Side;
		bool bInsideTimeBuffer = Math::Abs(MioData.TimeLastPaddled - ZoeData.TimeLastPaddled) < 0.2;
		return bSameSide && bInsideTimeBuffer;
	}

	float GetPlayerPaddleForwardSpeed(AHazePlayerCharacter Player) const
	{
		return PlayerPaddleData[Player].ForwardSpeed;
	}
	float GetPlayerPaddleRotationSpeed(AHazePlayerCharacter Player) const
	{
		if (PlayerPaddleData[Player].Side == ERaftPaddleSide::None)
			return 0;
		else if (PlayerPaddleData[Player].Side == ERaftPaddleSide::Left)
			return PlayerPaddleData[Player].RotationSpeed;
		else
			return -PlayerPaddleData[Player].RotationSpeed;
	}

	float GetTotalPaddleRotationSpeed()
	{
		return GetPlayerPaddleRotationSpeed(Game::Mio) + GetPlayerPaddleRotationSpeed(Game::Zoe);
	}

	float GetTotalForwardPaddleSpeed() const
	{
		return GetPlayerPaddleForwardSpeed(Game::Mio) + GetPlayerPaddleForwardSpeed(Game::Zoe);
	}

	bool IsPlayerPaddling(AHazePlayerCharacter Player)
	{
		return PaddlingPlayers[Player];
	}

	FVector GetPushingVolumeForce()
	{
		FVector Force = FVector::ZeroVector;
		for (auto Volume : OverlappedPushingVolumes)
		{
			Force += Volume.GetForceAtPointInOverlap(ActorLocation);
		}

		TListedActors<APaddleRaftPushingForceSpline> ForceSplines;
		for (auto Spline : ForceSplines)
		{
			Force += Spline.GetForceAtLocation(ActorLocation);
		}
		return Force;
	}

	UFUNCTION(BlueprintCallable, DevFunction, Category = "Paddle Raft")
	void StartPaddleRaft()
	{
		bHasStarted = true;
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Game::Mio.ActivateCamera(RaftCamera, 0.5, this);

		RemoveActorDisable(this);

		for (auto Player : Game::Players)
		{
			RequestComponent.StartInitialSheetsAndCapabilities(Player, this);

			auto RaftComp = UPaddleRaftPlayerComponent::Get(Player);
			RaftComp.PaddleRaft = this;
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction, Category = "Paddle Raft")
	void StopPaddleRaft()
	{
		bHasStarted = false;
		Game::Mio.ClearViewSizeOverride(this);
		Game::Mio.DeactivateCamera(RaftCamera);

		if (!bHasBlockedCapabilities)
		{
			BlockCapabilities(SummitRaftTags::PaddleRaft, this);
			bHasBlockedCapabilities = true;
		}

		for (auto Player : Game::Players)
		{
			RequestComponent.StopInitialSheetsAndCapabilities(Player, this);

			auto RaftComp = UPaddleRaftPlayerComponent::Get(Player);
			RaftComp.PaddleRaft = nullptr;
		}
	}

	void ApplyStaggerToBothPlayers(FSummitRaftHitStaggerData Data)
	{
		if (StaggerComps[Game::Mio] == nullptr)
			StaggerComps[Game::Mio] = USummitRaftPlayerStaggerComponent::Get(Game::Mio);

		if (StaggerComps[Game::Zoe] == nullptr)
			StaggerComps[Game::Zoe] = USummitRaftPlayerStaggerComponent::Get(Game::Zoe);

		StaggerComps[Game::Mio].ApplyStaggerData(Data);
		StaggerComps[Game::Zoe].ApplyStaggerData(Data);
		QueuedStaggerData.Set(Data);
	}

	float GetAverageWaterHeight() const
	{
		float WaterHeight = 0.0;
		for (auto SampleComp : SampleComponents)
			WaterHeight += SampleComp.GetHeightAtComponentLocation(WaterSplineActor.Spline);

		WaterHeight /= SampleComponents.Num();
		return WaterHeight;
	}

	bool HasWaterBellow() const
	{
		int NrOfPointsInWater = 0;
		for (auto SampleComp : SampleComponents)
		{
			if (SampleComp.HasWaterBellow(WaterSplineActor.Spline, 500))
				NrOfPointsInWater++;
		}
		return NrOfPointsInWater >= 3;
	}
};