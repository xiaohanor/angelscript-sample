struct FSkylineBallBossChargeLaserButtonMashExtrudePlayerActivationParams
{
	ASkylineBallBossChargeLaser MashedLaser = nullptr;
	ASkylineBallBossChargeLaserInteractLocation ClosestLocation = nullptr;
}

class USkylineBallBossChargeLaserButtonMashExtrudePlayerCapability : UHazePlayerCapability
{
	FSkylineBallBossChargeLaserButtonMashExtrudePlayerActivationParams Params;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::BeforeMovement;

	USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent ExtruderComponent;
	UButtonMashComponent MashyMash;
	UPlayerMovementComponent MovementComponent;
	USimpleMovementData SimpleMoveData;
	bool bExit = false;

	UPROPERTY()
	FButtonMashSettings MashSettings;
	default MashSettings.ProgressionMode = EButtonMashProgressionMode::MashToProgress;
	default MashSettings.bAllowPlayerCancel = true;

	float LastButtonMashProgress = 0.0;

	ECollisionEnabled PreviousMashedLaserCollision;
	ECollisionEnabled PreviousFrameCollision;
	FQuat UpRotationOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ExtruderComponent = USkylineBallBossChargeLaserButtonMashExtrudePlayerComponent::Get(Owner);
		MovementComponent = UPlayerMovementComponent::Get(Owner);
		SimpleMoveData = MovementComponent.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineBallBossChargeLaserButtonMashExtrudePlayerActivationParams & ActivationParams) const
	{
		if (ExtruderComponent.MashedLaser != nullptr)
		{
			ActivationParams.MashedLaser = ExtruderComponent.MashedLaser;
			ActivationParams.ClosestLocation = FindClosestInteractLocation();
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ExtruderComponent.MashedLaser == nullptr)
			return true;
		if (!IsInHandledState())
			return true;
		if (Player.IsPlayerDead())
			return true;
		if (!MashyMash.IsButtonMashActive(n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability"))
			return true;
		return false;
	}

	private bool IsInHandledState() const
	{
		if (Params.MashedLaser.GetState() == EBallBossWeakPointState::Extruding)
			return true;
		if (Params.MashedLaser.GetState() == EBallBossWeakPointState::Extruded)
			return true;
		if (Params.MashedLaser.GetState() == EBallBossWeakPointState::Tearing)
			return true;
		if (Params.MashedLaser.GetState() == EBallBossWeakPointState::Retracting)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineBallBossChargeLaserButtonMashExtrudePlayerActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		MovementComponent.ActiveConstrainRotationToHorizontalPlane.Apply(false, this, EInstigatePriority::High);
		
		ExtruderComponent.MashState = ESkylineBallBossPlayerMashState::Enter;
		Params = ActivationParams;
		MashyMash = UButtonMashComponent::Get(Player);
		MashyMash.OnVisualPulse.AddUFunction(this, n"MashFF");
		
		MashSettings.WidgetAttachComponent = ExtruderComponent.MashedLaser.InteractionMashUILocation;
		MashSettings.WidgetPositionOffset = FVector::ZeroVector;

		Player.StartButtonMash(MashSettings, n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability");
		MashyMash.SetAllowButtonMashCompletion(n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability", false);
		Params.MashedLaser.SetState(EBallBossWeakPointState::Extruding);
		UpRotationOffset = FQuat::MakeFromZ(Player.ActorRotation.UpVector) * FQuat::MakeFromZ(ExtruderComponent.MashedLaser.ActorQuat.UpVector).Inverse();

		DisableCollisionHacky();
		for (auto ProgressMesh : ExtruderComponent.MashedLaser.LaserProgressComponents)
			ProgressMesh.bSlowRetreat = false;

		//if (ExtruderComponent.CameraSettings != nullptr)
		//	Player.ApplyCameraSettings(ExtruderComponent.CameraSettings, 1.5, this, EHazeCameraPriority::Debug);

		if (ExtruderComponent.AnimationSettings.MHAnimation != nullptr)
			Player.PlaySlotAnimation(Animation = ExtruderComponent.AnimationSettings.MHAnimation, bLoop = true);

		MovementComponent.FollowComponentMovement(ActivationParams.ClosestLocation.Root, this, EMovementFollowComponentType::Teleport, EInstigatePriority::Interaction);
		// Timer::SetTimer(this, n"FindClosestInteractLocation", 0.2);

		ExtruderComponent.MashedLaser.bMioIsInteracting = true;
	}

	UFUNCTION()
	private void MashFF()
	{
		Player.PlayForceFeedback(ForceFeedback::Default_Medium_Short, this);
	}

	private void DisableCollisionHacky()
	{
		PreviousMashedLaserCollision = ExtruderComponent.MashedLaser.MeshPanelComp.GetCollisionEnabled();
		ExtruderComponent.MashedLaser.MeshPanelComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		TArray<USceneComponent> Children;
		ExtruderComponent.MashedLaser.BallBoss.SceneLaserWeakspotComponent.GetChildrenComponents(true, Children);
		for (auto Child : Children)
		{
			UStaticMeshComponent AsMesh = Cast<UStaticMeshComponent>(Child);
			if (AsMesh != nullptr)
			{
				PreviousFrameCollision = AsMesh.GetCollisionEnabled();
				AsMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}
	}

	private ASkylineBallBossChargeLaserInteractLocation FindClosestInteractLocation() const
	{
		ASkylineBallBossChargeLaserInteractLocation ClosestLocation = nullptr;
		float ClosestDistance = MAX_flt;
		for (auto InteractLocation : ExtruderComponent.MashedLaser.InteractionTeleportLocations)
		{
			float Distance = (Player.ActorLocation - InteractLocation.ActorLocation).Size();
			if (Distance < ClosestDistance)
			{
				ClosestDistance = Distance;
				ClosestLocation = InteractLocation;
			}
		}
		return ClosestLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MashyMash.OnVisualPulse.Unbind(this, n"MashFF");

		//Deactivating cinematic camera
		ExtruderComponent.MashedLaser.DeactivateFrameChargeLaserCamera();

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		MovementComponent.ActiveConstrainRotationToHorizontalPlane.Clear(this);

		MovementComponent.UnFollowComponentMovement(this);
		EnableCollisionHacky();

		if (ExtruderComponent.MashedLaser.GetState() == EBallBossWeakPointState::TornOff)
		{
			ExtruderComponent.bDoBackflip = true;

			USkylineBallBossMiscVOEventHandler::Trigger_ChargerExitRippedOff(ExtruderComponent.MashedLaser.BallBoss);
		}
		else
		{
			ExtruderComponent.MashState = ESkylineBallBossPlayerMashState::Cancel;
			for (auto ProgressMesh : ExtruderComponent.MashedLaser.LaserProgressComponents)
			{
				ProgressMesh.ProgressAlpha = 0.0;
				ProgressMesh.bSlowRetreat = true;
			}

			USkylineBallBossMiscVOEventHandler::Trigger_ChargerExitInteract(ExtruderComponent.MashedLaser.BallBoss);
		}

		if (ExtruderComponent.CameraSettings != nullptr)
			Player.ClearCameraSettingsByInstigator(this, 2.0);

		ExtruderComponent.MashedLaser.bMioIsInteracting = false;
		ExtruderComponent.MashedLaser = nullptr;
		Player.StopButtonMash(n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability");

		if (ExtruderComponent.AnimationSettings.MHAnimation != nullptr)
			Player.StopSlotAnimation();


	}
	
	private void EnableCollisionHacky()
	{
		ExtruderComponent.MashedLaser.MeshPanelComp.SetCollisionEnabled(PreviousMashedLaserCollision);
		
		TArray<USceneComponent> Children;
		ExtruderComponent.MashedLaser.BallBoss.SceneLaserWeakspotComponent.GetChildrenComponents(true, Children);
		for (auto Child : Children)
		{
			UStaticMeshComponent AsMesh = Cast<UStaticMeshComponent>(Child);
			if (AsMesh != nullptr)
				AsMesh.SetCollisionEnabled(PreviousFrameCollision);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// auto Data = MovementComponent.GetCurrentMovementFollowAttachment();
		// Debug::DrawDebugString(Owner.ActorLocation, "" + Data.Component.Owner.GetName());
		// ColorDebug::DrawTintedTransform(ExtruderComponent.MashedLaser.InteractionMashUILocation.WorldLocation, ExtruderComponent.MashedLaser.InteractionMashUILocation.WorldRotation, ColorDebug::White, 100);
		// UpRotation.AccelerateTo(ExtruderComponent.MashedLaser.ActorRotation, 0.01, DeltaTime);
		// Player.OverrideGravityDirection(-UpRotation.Value.UpVector, Skyline::GravityProxy, EInstigatePriority::High);

		UpRotationOffset = Math::QInterpConstantTo(UpRotationOffset, FQuat::Identity, DeltaTime, 1);

		if (MovementComponent.PrepareMove(SimpleMoveData, (UpRotationOffset * ExtruderComponent.MashedLaser.ActorQuat).UpVector))
		{
			if (HasControl())
			{
		
				// Player.OverrideGravityDirection(-UpRotation.Value.UpVector, Skyline::GravityProxy, EInstigatePriority::High);
				// Debug::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation + Player.GetGravityDirection() * 100.0, 10.0);
				// Debug::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation - UpRotation.Value.UpVector * 100.0, 10.0);
				// Debug::DrawDebugArrow(Player.ActorCenterLocation, Player.ActorCenterLocation + Player.ActorRotation.UpVector * 100.0, 10.0, ColorDebug::Cyan);
				//Player.OverrideGravityDirection(, Skyline::GravityProxy, EInstigatePriority::High);

				SimpleMoveData.SetRotation(Params.ClosestLocation.ActorRotation);
				FVector Delta = Params.ClosestLocation.ActorLocation - Player.ActorLocation;
				SimpleMoveData.AddDelta(Delta);
			}
			else
			{
				SimpleMoveData.ApplyCrumbSyncedGroundMovement();
			}
			MovementComponent.ApplyMove(SimpleMoveData);
		}

		auto MashedLaser = Params.MashedLaser;
		MashedLaser.AutoRetractTimer = MashedLaser.Settings.ExtrudeDuration;

		bool bIsButtonMashing = false;
		if (MashyMash != nullptr)
		{
			float CurrentButtonMashProgress = MashyMash.GetButtonMashProgress(n"SkylineBallBossChargeLaserButtonMashExtrudePlayerCapability");

			for (auto ProgressMesh : MashedLaser.LaserProgressComponents)
				ProgressMesh.ProgressAlpha = CurrentButtonMashProgress;

			bIsButtonMashing = CurrentButtonMashProgress >= 1.0 - KINDA_SMALL_NUMBER || CurrentButtonMashProgress > LastButtonMashProgress;
			LastButtonMashProgress = CurrentButtonMashProgress;
			MashedLaser.TargetAlphaHit = LastButtonMashProgress;

			if (bIsButtonMashing)
				MashedLaser.RecentlyHitCooldown = MashedLaser.Settings.ExtrudeRetractGraceTime;
		}
	}
}
