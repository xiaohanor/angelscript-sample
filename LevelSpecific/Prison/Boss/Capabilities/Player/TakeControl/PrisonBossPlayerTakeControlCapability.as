class UPrisonBossPlayerTakeControlCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TakeControl");

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	APrisonBoss BossActor;
	AHazePlayerCharacter Player;
	UPrisonBossPlayerTakeControlComponent TakeControlComp;
	URemoteHackingPlayerComponent RemoteHackingPlayerComp;

	UHazeMovementComponent MoveComp;
	USweepingMovementData Movement;
	UPlayerAimingComponent AimComp;
	UCameraUserComponent CameraUser;
	UHazeMovementComponent PlayerMoveComp;

	float RotSpeed = 60.0;

	float CameraPitch = 0.0;
	float MaxPitch = 45.0;

	FHazeAcceleratedVector2D AcceleratedInput;

	UPoseableMeshComponent FakeMeshComp;

	bool bAlignedWithMiddle = false;

	FVector Velocity;
	float MoveSpeed = 500.0;

	bool bUsingDeflectCamera = false;
	float DeflectTimer = 0.0;

	FRotator DesiredRotationPreDeflect;
	FHazeAcceleratedFloat BlendCameraToAlignBone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossActor = Cast<APrisonBoss>(Owner);
		Player = Game::Mio;

		TakeControlComp = UPrisonBossPlayerTakeControlComponent::Get(BossActor);
		MoveComp = UHazeMovementComponent::Get(BossActor);
		Movement = MoveComp.SetupSweepingMovementData();
		AimComp = UPlayerAimingComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!BossActor.bControlled)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!BossActor.bControlled)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FRotator StartRot;

		bAlignedWithMiddle = false;
		Velocity = FVector::ZeroVector;

		RemoteHackingPlayerComp = URemoteHackingPlayerComponent::Get(Player);
		PlayerMoveComp = UHazeMovementComponent::Get(Player);

		FakeMeshComp = UPoseableMeshComponent::Create(BossActor);
		FakeMeshComp.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::AlwaysTickPoseAndRefreshBones;
		FakeMeshComp.SetSkinnedAssetAndUpdate(BossActor.Mesh.SkeletalMeshAsset);
		FakeMeshComp.SetBoundsScale(2.0);
		
		for (int i = 0; i <= FakeMeshComp.NumMaterials - 1; i++)
		{
			FakeMeshComp.SetMaterial(i, BossActor.Mesh.Materials[i]);
		}
		
		FakeMeshComp.HideBoneByName(n"Head", EPhysBodyOp::PBO_None);

		BossActor.Mesh.SetRenderedForPlayer(Game::Mio, false);
		FakeMeshComp.SetRenderedForPlayer(Game::Zoe, false);

		CapabilityInput::LinkActorToPlayerInput(BossActor, Player);

		BossActor.AnimationData.bIsControlled = true;

		TArray<UNiagaraComponent> NiagaraComps;
		BossActor.GetComponentsByClass(UNiagaraComponent, NiagaraComps);
		for (UNiagaraComponent Comp : NiagaraComps)
		{
			Comp.SetRenderedForPlayer(Player, false);
		}

		TakeControlComp.CreateWidget();

		Player.ApplyOtherPlayerIndicatorMode(EOtherPlayerIndicatorMode::AlwaysVisible, this, EInstigatePriority::High);
		Player.BlockCapabilities(n"Death", this);
		Player.BlockCapabilities(CapabilityTags::CenterView, this);
		PostProcessing::ApplyPostProcessMaterial(Player, BossActor.FirstPersonPostProcessMat, this, EInstigatePriority::Override);
		RemoteHackingPlayerComp.TriggerPostProcessTransition();

		Player.CameraOffsetComponent.AttachToComponent(BossActor.FirstPersonTransitionComp);
		AimComp.ApplyAimingSensitivity(this);

		Player.ApplyCameraSettings(BossActor.TakeControlCameraSettings, 0.0, this, EHazeCameraPriority::VeryHigh);
		CameraUser.SetDesiredRotation(StartRot, this);

		Timer::SetTimer(this, n"AttachCameraToAlign", 1.0);

		CameraPitch = 0.0;

		if (BossActor.CurrentBrainPhase == 2)
			BossActor.SetDeflectStatus(true);

		UPrisonBossEffectEventHandler::Trigger_TakeControlEnter(BossActor);
	}

	UFUNCTION()
	private void AttachCameraToAlign()
	{
		Player.CameraOffsetComponent.AttachToComponent(BossActor.FirstPersonCameraComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);

		TakeControlComp.RemoveWidget();

		BossActor.AnimationData.bIsControlled = false;

		if (!BossActor.bThirdPhaseCompleted)
			BossActor.OnPlayerLostControl.Broadcast();

		Player.ClearOtherPlayerIndicatorMode(this);
		Player.UnblockCapabilities(n"Death", this);
		Player.UnblockCapabilities(CapabilityTags::CenterView, this);
		PostProcessing::ClearPostProcessMaterial(Player, this);

		Player.CameraOffsetComponent.AttachToComponent(Player.RootOffsetComponent);
		AimComp.ClearAimingSensitivity(this);

		BossActor.Mesh.UnHideBoneByName(n"Head");

		FakeMeshComp.DestroyComponent(BossActor);

		RemoteHackingPlayerComp.TriggerPostProcessTransition();

		UPrisonBossEffectEventHandler::Trigger_TakeControlExit(BossActor);

		Player.ClearCameraSettingsByInstigator(this);

		BossActor.Mesh.SetForcedLOD(0);

		if (bUsingDeflectCamera)
		{
			Player.UnblockCapabilities(CameraTags::CameraControl, this);
			bUsingDeflectCamera = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		BossActor.Mesh.SetForcedLOD(1);
		FakeMeshComp.CopyPoseFromSkeletalComponent(BossActor.Mesh);

		if (!bUsingDeflectCamera)
		{
			if (BossActor.bIsDeflecting)
			{
				BossActor.bHackedRotationFollowsCamera = false;
				DesiredRotationPreDeflect = CameraUser.GetDesiredRotation();

				Player.BlockCapabilities(CameraTags::CameraControl, this);
				bUsingDeflectCamera = true;
			}
		}
		else
		{
			DeflectTimer += DeltaTime;

			if (!BossActor.bIsDeflecting)
			{
				BlendCameraToAlignBone.AccelerateToWithStop(0.0, 0.3, DeltaTime, 0.1);
				if (BlendCameraToAlignBone.Value < 0.01)
				{
					CameraUser.SetDesiredRotation(DesiredRotationPreDeflect, this);
					BossActor.bHackedRotationFollowsCamera = true;
					Player.UnblockCapabilities(CameraTags::CameraControl, this);
					bUsingDeflectCamera = false;
				}
				else
				{
					CameraUser.SetDesiredRotation(
						Math::LerpShortestPath(
							DesiredRotationPreDeflect,
							BossActor.FirstPersonCameraComp.WorldRotation,
							BlendCameraToAlignBone.Value
						),
						this);
				}
			}
			else
			{
				BlendCameraToAlignBone.AccelerateTo(1.0, 0.3, DeltaTime);
				CameraUser.SetDesiredRotation(
					Math::LerpShortestPath(
						DesiredRotationPreDeflect,
						BossActor.FirstPersonCameraComp.WorldRotation,
						BlendCameraToAlignBone.Value
					),
					this);
			}
		}

		if (!bAlignedWithMiddle)
		{
			FVector BossTargetLoc = BossActor.MiddlePoint.ActorLocation;
			BossTargetLoc += FVector::UpVector * 400.0;
			FVector Loc = Math::VInterpTo(BossActor.ActorLocation, BossTargetLoc, DeltaTime, 4.0);
			BossActor.SetActorLocation(Loc);

			if (Loc.Equals(BossTargetLoc, 50.0))
				bAlignedWithMiddle = true;
		}
		else
		{
			if (!TakeControlComp.bDebrisLaunchActive)
			{
				if (MoveComp.PrepareMove(Movement))
				{
					if (HasControl())
					{
						const FVector2D MovementRaw = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
						FVector MoveInput = FVector(MovementRaw.X, MovementRaw.Y, 0.0);

						const float MoveInputSize = MoveInput.Size();
						MoveInput = Player.ViewTransform.Rotation.RotateVector(MoveInput).VectorPlaneProject(MoveComp.WorldUp).GetSafeNormal();
						MoveInput *= MoveInputSize;

						Velocity = Math::VInterpTo(Velocity, MoveInput * MoveSpeed, DeltaTime, 1.8);
						FVector DeltaMove = Velocity * DeltaTime;
						Movement.AddDelta(DeltaMove);
					}
					else
					{
						Movement.ApplyCrumbSyncedAirMovement();
					}

					MoveComp.ApplyMove(Movement);
				}
			}
		}
	}
}