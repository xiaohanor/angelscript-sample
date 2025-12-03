// Zoe
// Handles horizontal input and combining both the horizontal location and height into a move
// NOTE: This capability is on the PLAYER, not on the winch
class URemoteHackableWinchHookCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::Movement;

	URemoteHackableWinchPlayerComponent PlayerComp;
	ARemoteHackableWinch WinchActor;

	FHazeAcceleratedFloat AccFloat;
	UHazeMovementComponent WinchMoveComp;
	UPlayerHealthComponent HealthComp;
	UPlayerRespawnComponent RespawnComp;
	USweepingMovementData WinchMovement;

	const float CollisionRadius = 30;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp != nullptr)
		{
			if (PlayerComp.WinchActor != nullptr)
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp == nullptr)
			return true;

		if (PlayerComp.WinchActor == nullptr)
			return true;

		if (!PlayerComp.WinchActor.HackingComp.bHacked)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = URemoteHackableWinchPlayerComponent::GetOrCreate(Player);

		HealthComp = UPlayerHealthComponent::Get(Player);
		HealthComp.OnStartDying.AddUFunction(this, n"PlayerDied");

		RespawnComp = UPlayerRespawnComponent::Get(Player);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"Respawned");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerComp.bIsActive = true;
		WinchActor = PlayerComp.WinchActor;
		WinchMoveComp = WinchActor.MoveComp;
		WinchMovement = WinchMoveComp.SetupSweepingMovementData();
		WinchActor.SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		Player.AddLocomotionFeature(WinchActor.LocomotionFeatureBotHanging, this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"PlayerShadow", this);

		Player.AttachToComponent(WinchActor.HangRoot, NAME_None);
		Player.ApplyCameraSettings(WinchActor.HangingPlayerCamSettings, 2, this, EHazeCameraPriority::High);

		Player.CapsuleComponent.bOffsetBottomToAttachParentLocation = false;
		Player.CapsuleComponent.OverrideCapsuleSize(
			CollisionRadius,
			CollisionRadius,
			this
		);
		Player.CapsuleComponent.SetRelativeLocation(FVector(0, 0, CollisionRadius * 0.5));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		PlayerComp.bIsActive = false;

		if(IsValid(WinchActor))
			WinchActor.SyncedActorPosition.OverrideSyncRate(EHazeCrumbSyncRate::Low);
		
		Player.RemoveLocomotionFeature(WinchActor.LocomotionFeatureBotHanging, this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld);
		Player.ClearCameraSettingsByInstigator(this);

		Player.CapsuleComponent.bOffsetBottomToAttachParentLocation = true;
		Player.CapsuleComponent.ClearCapsuleSizeOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Player.RequestLocomotion(WinchActor.LocomotionFeatureBotHanging.Tag, this);
		if (PlayerComp.WinchActor.bButtonPushed)
			return;

		if (!WinchMoveComp.PrepareMove(WinchMovement))
			return;

		if(WinchActor.HasHorizontalControl())
		{
			const FVector2D MoveInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);

			const FVector MoveInputXY = FVector(MoveInput.Y, MoveInput.X, 0);
			WinchActor.SyncedActorPosition.SetSyncedMovementInput(MoveInputXY);

			const FVector Forward = Player.ViewRotation.ForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
			const FRotator Rotation = FRotator::MakeFromX(Forward);
			const FVector Move = Rotation.RotateVector(MoveInputXY) * Prison::RemoteHackableWinch::HorizontalMaxSpeed;

			FVector Velocity = WinchMoveComp.Velocity;
			Velocity += Move * DeltaTime;

			const float IntegratedDragFactor = Math::Exp(-Prison::RemoteHackableWinch::HorizontalDrag);
			Velocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaTime);

			WinchMovement.AddVelocity(Velocity);

			FVector BSValues = Move.GetSafeNormal();
			Player.SetAnimVector2DParam(n"BotHanging", FVector2D(BSValues.X * 0.5, -BSValues.Y * 0.5));
		}
		else
		{
			UHazeCrumbSyncedActorPositionComponent SyncedComp = WinchActor.SyncedActorPosition;

			// Get rid of the buffer length from the crumb trail by querying latest data
			float LatestCrumbTrailTime = 0;
			FHazeSyncedActorPosition ActorPos;
			SyncedComp.GetLatestAvailableData(ActorPos, LatestCrumbTrailTime);

			// Predict ahead by how far in the predicted past our latest data is
			// NOTE: We predict *more* into the future, because the FInterpTo later on is going to cause delay!
			float PredictTime = (Time::OtherSideCrumbTrailSendTimePrediction - LatestCrumbTrailTime) + 0.3;

			FVector SyncedVelocity = ActorPos.WorldVelocity;
			SyncedVelocity.Z = 0;

			FVector SyncedLocation = ActorPos.WorldLocation + (SyncedVelocity * PredictTime);
			FRotator SyncedRotation = ActorPos.WorldRotation;
			
			// Do some interpolation with current position to make it smoother
			SyncedLocation = Math::VInterpTo(WinchActor.ActorLocation, SyncedLocation, DeltaTime, 3.0);
			SyncedRotation = Math::RInterpShortestPathTo(WinchActor.ActorRotation, SyncedRotation, DeltaTime, 5.0);

			WinchMovement.ApplyManualSyncedLocationAndRotation(SyncedLocation, SyncedVelocity, SyncedRotation);
		}

		WinchMoveComp.ApplyMove(WinchMovement);

		// Make sure that we never stray from our vertical location!
		FVector ActorLocation = WinchActor.ActorLocation;
		ActorLocation.Z = WinchActor.DefaultHeight;
		WinchActor.SetActorLocation(ActorLocation);
	}

	UFUNCTION()
	private void PlayerDied()
	{
		if (!IsActive())
			return;

		WinchActor.bHangingPlayerDead = true;
		FadeOutFullscreen(this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		WinchActor.SyncedCurrentHeight.SetValue(WinchActor.HookRoot.RelativeLocation.Z);
		WinchActor.SyncedHeightVelocity.SetValue(0);
		WinchActor.SyncedHeightInput.SetValue(0);
	}

	UFUNCTION()
	private void Respawned(AHazePlayerCharacter RespawnedPlayer)
	{
		if (!IsActive())
			return;

		const FVector RespawnLocation = RespawnedPlayer.ActorLocation;

		WinchActor.SetActorLocation(FVector(RespawnLocation.X, RespawnLocation.Y, WinchActor.DefaultHeight));
		WinchActor.HookRoot.SetWorldLocation(RespawnLocation);

		WinchActor.SyncedCurrentHeight.SetValue(WinchActor.HookRoot.RelativeLocation.Z);
		WinchActor.SyncedHeightVelocity.SetValue(0);
		WinchActor.SyncedHeightInput.SetValue(0);

		WinchActor.SyncedCurrentHeight.TransitionSync(this);
		WinchActor.SyncedHeightVelocity.TransitionSync(this);

		Player.AttachToComponent(WinchActor.HangRoot);

		WinchActor.bHangingPlayerDead = false;
		ClearFullscreenFade(this);
		Player.SnapCameraBehindPlayerWithCustomOffset(FRotator(-65.0, 0.0, 0.0));
	}
}