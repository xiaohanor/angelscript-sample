event void FOnStoneBeastHeadFinalShakeEnded();

struct FStoneBeastFocusTargetData
{
	bool bIsFollowing;
	AStoneBeastHeadFocusTarget FocusTarget;
}

enum EStoneBeastHeadRotationActionType
{
	None UMETA(Hidden),
	ShakeTelegraph,
	Roll,
	Shake,
	Reset,
	Wait,
	RollTelegraph
}

struct FStoneBeastHeadRotationAxisSettings
{
	FStoneBeastHeadRotationAxisSettings(float InAmplitude, float InFrequency)
	{
		this.Amplitude = InAmplitude;
		this.Frequency = InFrequency;
	}
	// Rotation amount (degrees)
	UPROPERTY()
	float Amplitude;

	// Oscillation times per second
	UPROPERTY()
	float Frequency;
}

struct FStoneBeastHeadCameraData
{
	UPROPERTY()
	AFocusCameraActor CameraActor;

	UPROPERTY()
	float CameraBlendInTime = 3.0;

	UPROPERTY()
	float CameraBlendOutTime = 3.0;
}

struct FStoneBeastHeadActionParams
{
	FStoneBeastHeadActionParams(float ActionDuration, FRotator ActionStartRotation)
	{
		Duration = ActionDuration;
		StartRotation = ActionStartRotation;
	}
	FRotator StartRotation;
	float Duration;
}

class AStoneBeastHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Movable;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HeadPivot;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	USceneComponent AcidAttach;

	UPROPERTY(DefaultComponent, Attach = HeadPivot)
	UScenepointComponent TailAttach;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"StoneBeastHeadCameraFocusUpdaterCapability");

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;

	UPROPERTY(EditDefaultsOnly, Category = "StoneBeastHead|Setup")
	UHazeCameraSettingsDataAsset RollCameraSetting;

	UPROPERTY(EditDefaultsOnly, Category = "StoneBeastHead|Setup")
	float RollCameraSettingBlendTime = 1;

	// SHAKE CAMERA
	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead|Cameras")
	FStoneBeastHeadCameraData ShakeCameraData;

	// ROLL CAMERA
	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead|Cameras")
	FStoneBeastHeadCameraData RollCameraData;

	// SHAKETELEGRAPH CAMERA
	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead|Cameras")
	FStoneBeastHeadCameraData ShakeTelegraphCameraData;

	// ROLLTELEGRAPH CAMERA
	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead|Cameras")
	FStoneBeastHeadCameraData RollTelegraphCameraData;

	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead|Cameras")
	AFocusCameraActor DefaultFocusCameraActor;

	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead")
	ABothPlayerTrigger FinalPinCheckPlayerTrigger;

	UPROPERTY(EditAnywhere, Category = "StoneBeastHead")
	TArray<AActor> ActorsToRollWithHead;

	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead")
	AStoneBeastAdulDragonBase AcidDragon;
	FVector AcidDragonStartOffset = ActorLocation + ActorRightVector * 8000.0;

	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead")
	AStoneBeastAdulDragonBase TailDragon;
	FVector TailDragonStartOffset = ActorLocation - ActorRightVector * 8000.0;

	UPROPERTY(EditDefaultsOnly, Category = "StoneBeastHead")
	UAnimSequence TailIdle;

	UPROPERTY(EditDefaultsOnly, Category = "StoneBeastHead")
	UAnimSequence AcidIdle;

	UPROPERTY(EditInstanceOnly, Category = "StoneBeastHead")
	bool bPreviewAttachDragons;

	UPROPERTY()
	FOnStoneBeastHeadFinalShakeEnded OnStoneBeastHeadFinalShakeEnded;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueue;

	TPerPlayer<bool> PlayerRespawnBlocks;
	bool bHasStartedShaking = false;
	bool bHasStartedRolling = false;

	bool bBothPlayersInsideFinalTrigger = false;
	TPerPlayer<FStoneBeastFocusTargetData> FocusTargets;

	int SequenceIndex = 0;
	int ActionIndex = 0;

	private bool bFocusTargetsInitialized;
	private bool bIsShakeCameraActive = false;
	private bool bIsShakeTelegraphCameraActive = false;
	private bool bIsRollCameraActive = false;
	private bool bIsRollTelegraphCameraActive = false;

	// FRotator StartRotation;

	bool bIsActive = false;

	TArray<AActor> AttachedActors;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewAttachDragons)
		{
			AcidDragon.AttachToComponent(AcidAttach, NAME_None, EAttachmentRule::SnapToTarget);
			TailDragon.AttachToComponent(TailAttach, NAME_None, EAttachmentRule::SnapToTarget);
		}
		else
		{
			AcidDragon.DetachFromActor(EDetachmentRule::KeepWorld);
			TailDragon.DetachFromActor(EDetachmentRule::KeepWorld);
			AcidDragon.ActorLocation = AcidDragonStartOffset;
			TailDragon.ActorLocation = TailDragonStartOffset;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetAttachedActorsToBone();

		if (!HasControl())
			return;

		if (bPreviewAttachDragons)
		{
			AcidDragon.DetachFromActor(EDetachmentRule::KeepWorld);
			TailDragon.DetachFromActor(EDetachmentRule::KeepWorld);
		}

		AcidDragon.ActorLocation = AcidDragonStartOffset;
		TailDragon.ActorLocation = TailDragonStartOffset;

		FinalPinCheckPlayerTrigger.OnBothPlayersInside.AddUFunction(this, n"OnBothPlayersInsideFinalTrigger");
		FinalPinCheckPlayerTrigger.OnStopBothPlayersInside.AddUFunction(this, n"OnStopBothPlayersInsideTrigger");
		// StartRotation = ActorRotation;

		{
			// Shake Action Sequence
			ActionQueue.Capability(UStoneBeastHeadShakeTelegraphCapability,
								   FStoneBeastHeadActionParams(ActionDuration = 2.0, ActionStartRotation = ActorRotation));
			ActionQueue.Capability(UStoneBeastHeadShakeActiveCapability,
								   FStoneBeastHeadActionParams(ActionDuration = 5.0, ActionStartRotation = ActorRotation));
			ActionQueue.Capability(UStoneBeastHeadShakeResetCapability,
								   FStoneBeastHeadActionParams(ActionDuration = 2.0, ActionStartRotation = ActorRotation));
		}

		// Wait
		ActionQueue.Capability(UStoneBeastHeadWaitCapability,
							   FStoneBeastHeadActionParams(ActionDuration = 2, ActionStartRotation = ActorRotation));

		{
			// Roll Action Sequence
			ActionQueue.Capability(UStoneBeastHeadRollTelegraphCapability,
								   FStoneBeastHeadActionParams(ActionDuration = 2.25, ActionStartRotation = ActorRotation));
			ActionQueue.Capability(UStoneBeastHeadRollCapability,
								   FStoneBeastHeadActionParams(ActionDuration = 5.0, ActionStartRotation = ActorRotation));
		}

		// Wait
		ActionQueue.Capability(UStoneBeastHeadWaitCapability,
							   FStoneBeastHeadActionParams(ActionDuration = 2.0, ActionStartRotation = ActorRotation));

		ActionQueue.SetLooping(true);

		SkelMesh.HideBoneByName(n"LeftEye", EPhysBodyOp::PBO_None);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TEMPORAL_LOG(this).Value("Rotation", ActorRotation);
	}

	UFUNCTION()
	void AttachDragonToComponent()
	{
		AcidDragon.AttachToActor(this, n"Head", EAttachmentRule::KeepWorld);
		TailDragon.AttachToActor(this, n"Head", EAttachmentRule::KeepWorld);
		FHazeSlotAnimSettings Settings;
		Settings.bLoop = true;
		TailDragon.PlaySlotAnimation(TailIdle, Settings);
		AcidDragon.PlaySlotAnimation(AcidIdle, Settings);
	}

	UFUNCTION()
	void OnBothPlayersInsideFinalTrigger()
	{
		bBothPlayersInsideFinalTrigger = true;
	}

	UFUNCTION()
	void OnStopBothPlayersInsideTrigger()
	{
		bBothPlayersInsideFinalTrigger = false;
	}

	void BlockRespawnCapabilities(AHazePlayerCharacter Player)
	{
		if (PlayerRespawnBlocks[Player])
			return;

		Player.BlockCapabilities(n"Respawn", this);
		PlayerRespawnBlocks[Player] = true;
	}

	void UnblockRespawnCapabilities(AHazePlayerCharacter Player)
	{
		if (!PlayerRespawnBlocks[Player])
			return;

		Player.UnblockCapabilities(n"Respawn", this);
		PlayerRespawnBlocks[Player] = false;
	}

	bool CheckBothPlayersAttachedToFinalPoint()
	{
		bool bBothPlayersPinned = true;
		for (auto Player : Game::Players)
		{
			auto PinComp = UDragonSwordPinToGroundComponent::Get(Player);
			if (!PinComp.IsPlayerPinnedToGround())
			{
				bBothPlayersPinned = false;
				break;
			}
		}
		return bBothPlayersPinned && bBothPlayersInsideFinalTrigger;
	}

	UFUNCTION()
	void CreateCameraFocusTargets()
	{
		CreateFocusTargets();
	}

	UFUNCTION(DevFunction)
	void StartShaking()
	{
		bIsActive = true;
	}

	void TryTriggerEnding()
	{
		if (bBothPlayersInsideFinalTrigger && HasControl())
		{
			CrumbTriggerEnding();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTriggerEnding()
	{
		OnStoneBeastHeadFinalShakeEnded.Broadcast();
		ActionQueue.SetPaused(true);
		bIsActive = false;
	}

	void ActivateCameraForAction(EStoneBeastHeadRotationActionType Action)
	{
		switch (Action)
		{
			case EStoneBeastHeadRotationActionType::ShakeTelegraph:
				Game::Zoe.ActivateCamera(ShakeTelegraphCameraData.CameraActor, ShakeTelegraphCameraData.CameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
				bIsShakeTelegraphCameraActive = true;
				break;
			case EStoneBeastHeadRotationActionType::Shake:
				Game::Zoe.ActivateCamera(ShakeCameraData.CameraActor, ShakeCameraData.CameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
				bIsShakeCameraActive = true;
				break;
			case EStoneBeastHeadRotationActionType::Roll:
				Game::Zoe.ActivateCamera(RollCameraData.CameraActor, RollCameraData.CameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
				bIsRollCameraActive = true;
				break;
			case EStoneBeastHeadRotationActionType::RollTelegraph:
				Game::Zoe.ActivateCamera(RollTelegraphCameraData.CameraActor, RollTelegraphCameraData.CameraBlendInTime, this, EHazeCameraPriority::VeryHigh);
				bIsRollTelegraphCameraActive = true;
				break;
			default:
				break;
		}
	}

	void DeactivateCameraForAction(EStoneBeastHeadRotationActionType Action)
	{
		switch (Action)
		{
			case EStoneBeastHeadRotationActionType::ShakeTelegraph:
				if (bIsShakeTelegraphCameraActive)
					Game::Zoe.DeactivateCamera(ShakeTelegraphCameraData.CameraActor, ShakeTelegraphCameraData.CameraBlendOutTime);
				bIsShakeTelegraphCameraActive = false;
				break;
			case EStoneBeastHeadRotationActionType::Shake:
				if (bIsShakeCameraActive)
					Game::Zoe.DeactivateCamera(ShakeCameraData.CameraActor, ShakeCameraData.CameraBlendOutTime);
				bIsShakeCameraActive = false;
				break;
			case EStoneBeastHeadRotationActionType::Roll:
				if (bIsRollCameraActive)
					Game::Zoe.DeactivateCamera(RollCameraData.CameraActor, RollCameraData.CameraBlendOutTime);
				bIsRollCameraActive = false;
				break;
			case EStoneBeastHeadRotationActionType::RollTelegraph:
				if (bIsRollTelegraphCameraActive)
					Game::Zoe.DeactivateCamera(RollTelegraphCameraData.CameraActor, RollTelegraphCameraData.CameraBlendOutTime);
				bIsRollTelegraphCameraActive = false;
				break;
			default:
				break;
		}
	}

	void DetachFocusTargets()
	{
		FocusTargets[Game::Mio].FocusTarget.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		FocusTargets[Game::Zoe].FocusTarget.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	void AttachFocusTargets()
	{
		FocusTargets[Game::Mio].FocusTarget.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
		FocusTargets[Game::Zoe].FocusTarget.AttachToActor(this, NAME_None, EAttachmentRule::KeepWorld);
	}

	void CreateFocusTargets()
	{
		if (bFocusTargetsInitialized)
			return;

		for (auto Player : Game::Players)
		{
			FHazeCameraWeightedFocusTargetInfo TargetInfo;
			auto Location = Player.ActorCenterLocation;
			FocusTargets[Player].FocusTarget = SpawnActor(AStoneBeastHeadFocusTarget, Location);
			TargetInfo.SetFocusToActor(FocusTargets[Player].FocusTarget);
			TargetInfo.AdvancedSettings.LocalOffset = StoneBeastHead::FocusTarget::LocalOffset;
			TargetInfo.AdvancedSettings.ViewOffset = StoneBeastHead::FocusTarget::ViewOffset;
			TargetInfo.AdvancedSettings.UsedBy = EHazeSelectPlayer::Both;

			DefaultFocusCameraActor.FocusTargetComponent.AddFocusTarget(TargetInfo, this);
			RollCameraData.CameraActor.FocusTargetComponent.AddFocusTarget(TargetInfo, this);
			RollTelegraphCameraData.CameraActor.FocusTargetComponent.AddFocusTarget(TargetInfo, this);
			ShakeTelegraphCameraData.CameraActor.FocusTargetComponent.AddFocusTarget(TargetInfo, this);
			ShakeCameraData.CameraActor.FocusTargetComponent.AddFocusTarget(TargetInfo, this);

			FocusTargets[Player].bIsFollowing = true;
		}

		AttachFocusTargets();
		bFocusTargetsInitialized = true;
	}

	void UpdateFocusTargetsLocation(float DeltaTime)
	{
		for (auto Player : Game::GetPlayers())
		{
			AHazePlayerCharacter TargetPlayer = Player;
			if (Player.IsPlayerDeadOrRespawning())
			{
				TargetPlayer = Player.OtherPlayer;
				if (TargetPlayer.IsPlayerDeadOrRespawning())
					continue;
			}

			if (!FocusTargets[TargetPlayer].bIsFollowing)
				continue;

			// FocusTargets should follow players but not be affected by jumps,
			// get the grounded location from trace
			FHazeTraceSettings Settings = Trace::InitFromPlayer(TargetPlayer);
			Settings.UseLine();

			auto HitResult = Settings.QueryTraceSingle(TargetPlayer.ActorCenterLocation, TargetPlayer.ActorCenterLocation + TargetPlayer.GetGravityDirection() * 2000);
			if (!HitResult.bBlockingHit)
				continue;

			FVector NewLocation = TargetPlayer.ActorCenterLocation;
			float HeightOffset = TargetPlayer.ActorCenterLocation.Z - TargetPlayer.ActorLocation.Z;
			NewLocation.Z = HitResult.ImpactPoint.Z + HeightOffset;

			float Distance = FocusTargets[TargetPlayer].FocusTarget.ActorLocation.Distance(NewLocation);
			float InterpSpeed = Math::NormalizeToRange(Distance, 0, StoneBeastHead::FocusTarget::InterpMaxDistance) * StoneBeastHead::FocusTarget::InterpMaxSpeed;
			FocusTargets[TargetPlayer].FocusTarget.ActorLocation = Math::VInterpTo(FocusTargets[TargetPlayer].FocusTarget.ActorLocation, NewLocation, DeltaTime, InterpSpeed);
		}
	}

	UFUNCTION()
	void SetAttachedActorsToBone()
	{
		GetAttachedActors(AttachedActors);

		for (AActor Actor : AttachedActors)
		{
			Actor.AttachToComponent(SkelMesh, n"Head", EAttachmentRule::KeepWorld);
		}
	}
};