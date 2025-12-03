
UCLASS(Abstract)
class AWaveRaft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComponent;
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWaveRaftMovementCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWaveRaftCameraCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWaveRaftPaddleRotationCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWaveRaftStaggerRotationCapability);
	default CapabilityComponent.DefaultCapabilityClasses.Add(UWaveRaftCollisionCapability);

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedActorPositionComponent SyncPosComp;
	default SyncPosComp.SyncDetailLevel = EHazeActorPositionSyncDetailLevel::Player;
	default SyncPosComp.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent RequestComponent;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent VehicleOffsetRoot;

	UPROPERTY(DefaultComponent, Attach = VehicleOffsetRoot)
	UHazeOffsetComponent MeshOffsetComp;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USceneComponent MioAttachPoint;

	UPROPERTY(DefaultComponent, Attach = MeshOffsetComp)
	USceneComponent ZoeAttachPoint;

	UPROPERTY(DefaultComponent)
	USpringArmCamera RaftCamera;

	UPROPERTY(DefaultComponent)
	UWaveRaftMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CollisionCapsule;
	default CollisionCapsule.SetCollisionProfileName(n"Vehicle");
	default CollisionCapsule.SetCollisionObjectType(ECollisionChannel::ECC_Vehicle);
	// default CollisionCapsule.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	// default CollisionCapsule.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Ignore);
	default CollisionCapsule.SetCollisionResponseToChannel(SummitRaft::RaftCollisionChannel, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Wave Raft")
	AHazeActor SplineActor;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Camera")
	AHazeCameraActor CameraActor;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Player Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	UHazeSplineComponent SplineComp;
	FSplinePosition SplinePos;
	FHazeAcceleratedFloat AccCurrentRaftSpeed;
	FHazeAcceleratedRotator AccWaveRaftRotation;
	FHazeAcceleratedFloat AccYawSpeed;

	float TargetYawOffsetFromSpline = 0.0;

	bool bRaftIsOnWave = true;
	bool bRaftIsInWater = false;
	bool bHasBlockedCapabilities = false;

	const float WaterCheckDistance = 400;

	UPROPERTY(DefaultComponent, Attach = Root)
	URaftWaterSampleComponent FLWaterSampleComp;
	default FLWaterSampleComp.RelativeLocation = FVector(250, -60, 0);
	UPROPERTY(DefaultComponent, Attach = Root)
	URaftWaterSampleComponent FRWaterSampleComp;
	default FRWaterSampleComp.RelativeLocation = FVector(250, 60, 0);
	UPROPERTY(DefaultComponent, Attach = Root)
	URaftWaterSampleComponent BLWaterSampleComp;
	default BLWaterSampleComp.RelativeLocation = FVector(-250, -60, 0);
	UPROPERTY(DefaultComponent, Attach = Root)
	URaftWaterSampleComponent BRWaterSampleComp;
	default BRWaterSampleComp.RelativeLocation = FVector(-250, 60, 0);

	UPROPERTY(EditAnywhere)
	ASplineActor DefaultWaterSplineActor;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> BigJumpCamShake;

	UPROPERTY()
	UForceFeedbackEffect BigJumpFF;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SmallJumpCamShake;

	UPROPERTY()
	UForceFeedbackEffect SmallJumpFF;

	TArray<URaftWaterSampleComponent> SampleComponents;

	TPerPlayer<USummitRaftPlayerStaggerComponent> StaggerComps;
	UWaveRaftSettings RaftSettings;

	TOptional<FSummitRaftHitStaggerData> StaggerData;

	TInstigated<ASplineActor> InstigatedWaterSplineActor;

	bool bHasStarted = false;
	bool bIsFalling = false;
	bool bHasQueuedCameraSnap = false;
	bool bHasQueuedSmallJumpLanding;
	bool bHasQueuedBigJumpLanding;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InstigatedWaterSplineActor.SetDefaultValue(DefaultWaterSplineActor);
		AddActorDisable(this);
		MoveComp.SetupShapeComponent(CollisionCapsule);

		GetComponentsByClass(URaftWaterSampleComponent, SampleComponents);

		if (SplineActor != nullptr)
		{
			SplineComp = Spline::GetGameplaySpline(SplineActor, this);
			SplinePos = SplineComp.GetSplinePositionAtSplineDistance(0.0);
			FTransform SplinePosTransform = SplinePos.WorldTransform;
			SetActorLocationAndRotation(SplinePosTransform.Location, SplinePosTransform.Rotator(), true);
		}

		RaftSettings = UWaveRaftSettings::GetSettings(this);
		AccCurrentRaftSpeed.SnapTo(RaftSettings.RaftForwardTargetSpeed);
		UMovementGravitySettings::SetGravityAmount(this, RaftSettings.GravityForce, this);

		SampleComponents.SetNum(4);
		SampleComponents[0] = FLWaterSampleComp;
		SampleComponents[1] = FRWaterSampleComp;
		SampleComponents[2] = BLWaterSampleComp;
		SampleComponents[3] = BRWaterSampleComp;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
#if EDITOR
		auto Log = TEMPORAL_LOG(this);
		Log.Value("bIsFalling", bIsFalling);
		Log.Value("Transform", ActorTransform);
		Log.DirectionalArrow("ActorForwardVector", ActorLocation, ActorForwardVector * 2000);
		Log.Sphere("SplinePos", SplinePos.WorldLocation, 100, FLinearColor::LucBlue, 10);
		Log.Value("AccCurrentRaftSpeed", AccCurrentRaftSpeed.Value);
		Log.Value("AccYawSpeed", AccYawSpeed.Value);
		Log.Value("AccWaveRaftRotation", AccWaveRaftRotation.Value);
		Log.DirectionalArrow("AccWaveRaftRotationForward", ActorLocation, AccWaveRaftRotation.Value.ForwardVector * 2000, 5, 20, FLinearColor::Yellow);
		if (InstigatedWaterSplineActor.Get() != nullptr)
			Log.Value("InstigatedWaterSpline", InstigatedWaterSplineActor.Get());
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbQueueLandingFFAndCamShake(bool bIsBigJump)
	{
		if (bIsBigJump)
			bHasQueuedBigJumpLanding = true;
		else
			bHasQueuedSmallJumpLanding = true;
	}

	void ApplyWaveRaftSettings(UWaveRaftSettings Settings, FInstigator Instigator, EHazeSettingsPriority Priority)
	{
		ApplySettings(Settings, Instigator);
		UMovementGravitySettings::SetGravityAmount(this, RaftSettings.GravityForce, Instigator, Priority);
	}

	void ClearWaveRaftSettingsByInstigator(FInstigator Instigator)
	{
		ClearSettingsByInstigator(Instigator);
		UMovementGravitySettings::ClearGravityAmount(this, Instigator);
	}

	ASplineActor GetCurrentWaterSplineActor() const property
	{
		return InstigatedWaterSplineActor.Get();
	}

	void ApplyStaggerData(FSummitRaftHitStaggerData Data)
	{
		if (StaggerComps[Game::Mio] == nullptr)
			StaggerComps[Game::Mio] = USummitRaftPlayerStaggerComponent::Get(Game::Mio);

		if (StaggerComps[Game::Zoe] == nullptr)
			StaggerComps[Game::Zoe] = USummitRaftPlayerStaggerComponent::Get(Game::Zoe);

		StaggerComps[Game::Mio].ApplyStaggerData(Data);
		StaggerComps[Game::Zoe].ApplyStaggerData(Data);

		StaggerData = Data;
	}

	UFUNCTION(Category = "Wave Raft")
	void StopWater()
	{
		bRaftIsOnWave = false;
	}

	UFUNCTION(Category = "Wave Raft")
	void StartWaveRaftAtLocation(FVector Location, FRotator OverrideRotation = FRotator::ZeroRotator, bool bDisableWave = false, float CameraBlendTime = 0.5)
	{
		if (bDisableWave)
			StopWater();

		if (SplineActor != nullptr)
		{
			SplineComp = Spline::GetGameplaySpline(SplineActor, this);
			SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(Location);
			FTransform SplinePosTransform = SplinePos.WorldTransform;
			FRotator NewRotation = SplinePosTransform.Rotator();
			if (OverrideRotation != FRotator::ZeroRotator)
				NewRotation = OverrideRotation;
			TeleportActor(Location, NewRotation, this);
			AccWaveRaftRotation.SnapTo(NewRotation);
			bHasQueuedCameraSnap = Math::IsNearlyZero(CameraBlendTime);
		}

		StartWaveRaft(CameraBlendTime);
	}

	UFUNCTION(BlueprintCallable, DevFunction, Category = "Wave Raft")
	void StartWaveRaft(float CameraBlendTime = 0.5)
	{
		if (SplineActor != nullptr)
		{
			SplineComp = Spline::GetGameplaySpline(SplineActor, this);
			SplinePos = SplineComp.GetClosestSplinePositionToWorldLocation(ActorLocation);
			AccWaveRaftRotation.SnapTo(ActorRotation);
		}
		bHasStarted = true;
		if (bHasBlockedCapabilities)
		{
			UnblockCapabilities(SummitRaftTags::WaveRaft, this);
			bHasBlockedCapabilities = false;
		}

		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);

		if (CameraActor != nullptr)
			Game::Mio.ActivateCamera(CameraActor, CameraBlendTime, this);
		else
			Game::Mio.ActivateCamera(RaftCamera, CameraBlendTime, this);

		if (CameraSettings != nullptr)
			Game::Mio.ApplyCameraSettings(CameraSettings, CameraBlendTime, this, EHazeCameraPriority::Low);

		RemoveActorDisable(this);

		for (auto Player : Game::Players)
		{
			RequestComponent.StartInitialSheetsAndCapabilities(Player, this);

			auto RaftComp = UWaveRaftPlayerComponent::Get(Player);
			RaftComp.WaveRaft = this;
		}
	}

	UFUNCTION(BlueprintCallable, DevFunction, Category = "Wave Raft")
	void StopWaveRaft(bool bWasGameOver = false)
	{
		if (!bHasBlockedCapabilities)
		{
			BlockCapabilities(SummitRaftTags::WaveRaft, this);
			bHasBlockedCapabilities = true;
		}

		if (bHasStarted && !bWasGameOver)
		{
			for (auto Player : Game::Players)
			{
				RequestComponent.StopInitialSheetsAndCapabilities(Player, this);

				auto RaftComp = UWaveRaftPlayerComponent::Get(Player);
				RaftComp.WaveRaft = nullptr;
				Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			}
		}

		if (!bWasGameOver)
		{
			if (CameraActor != nullptr)
				Game::Mio.DeactivateCamera(CameraActor);
			else
				Game::Mio.DeactivateCamera(RaftCamera);

			Game::Mio.ClearViewSizeOverride(this);
		}

		bHasStarted = false;
	}

	bool IsFalling() const
	{
		if (bRaftIsOnWave)
			return false;

		return bIsFalling;
	}

	float GetAverageWaterHeight() const
	{
		float WaterHeight = 0.0;
		for (auto SampleComp : SampleComponents)
			WaterHeight += SampleComp.GetHeightAtComponentLocation(CurrentWaterSplineActor.Spline);

		WaterHeight /= SampleComponents.Num();
		return WaterHeight;
	}

	bool HasWaterBellow(float DistanceDownwards) const
	{
		int NumHits = 0;
		for (auto SampleComp : SampleComponents)
		{
			if (SampleComp.HasWaterBellow(CurrentWaterSplineActor.Spline, DistanceDownwards))
				NumHits++;
		}
		return NumHits >= 3;
	}

	UFUNCTION(CrumbFunction)
	void CrumbExplodeWaveRaft()
	{
		BP_ExplodeWaveRaft();
		StopWaveRaft(bWasGameOver = true);
		for (auto Player : Game::GetPlayers())
		{
			Player.KillPlayer();
			if (!Player.HasControl())
			{
				Player.BlockCapabilities(CapabilityTags::Visibility, this);
				Player.BlockCapabilities(n"BlockedWhileDead", this);
			}
		}

		FWaveRaftExplosionEventParams Params;
		Params.WaveRaftLocation = ActorLocation;
		UWaveRaftEventHandler::Trigger_OnRaftExploded(this, Params);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ExplodeWaveRaft()
	{}
};