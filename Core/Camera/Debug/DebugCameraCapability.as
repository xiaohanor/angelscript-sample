#if TEST
const FConsoleVariable UDebugCameraHideLockButtonConsole("Haze.DebugCameraShowButtonsInLockedView", DefaultValue = 1);

class UDebugCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CameraTags::CameraDebugCamera);
	default DebugCategory = CameraTags::CameraDebugCamera;

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 90;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UCameraUserComponent UserComp;
	UCameraDebugUserComponent DebugUserComp;
	UCameraSettings CameraSettings;
	ADebugCameraActor DebugCamera;
	UDebugCameraControlsWidget Widget;

	bool bLockView;
	FHitResult TeleportHit;
	FVector AxisMovement;
	float TapSpeedFactor;
	FHazeAcceleratedFloat HoldSpeedFactor;
	float IncreaseSpeedTimeStarted;
	float DecreaseSpeedTimeStarted;
	int SpeedDirection;
	float SpeedDirectionMultiplier = 1.0;
	float SpeedAttributeFactor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = UCameraUserComponent::Get(Owner);
		DebugUserComp = UCameraDebugUserComponent::GetOrCreate(Owner);
		CameraSettings = UCameraSettings::GetSettings(Player);

		if (DebugUserComp.DebugCamera == nullptr)
		{
			DebugCamera = Cast<ADebugCameraActor>(
				SpawnActor(ADebugCameraActor,
						   Owner.ActorLocation,
						   Owner.ActorRotation,
						   bDeferredSpawn = true));

			DebugCamera.MakeNetworked(Player, n"DebugCamera");
			DebugCamera.SetActorControlSide(Player);
			FinishSpawningActor(DebugCamera);

			DebugUserComp.DebugCamera = DebugCamera;
		}
		else
		{
			DebugCamera = DebugUserComp.DebugCamera;
		}

		FHazeDevInputInfo ToggleInputInfo;
		ToggleInputInfo.Name = n"Toggle Debug Camera";
		ToggleInputInfo.Category = n"Default";
		ToggleInputInfo.DisplaySortOrder = 210;
		ToggleInputInfo.OnTriggered.BindUFunction(this, n"HandleToggleDebugCamera");
		ToggleInputInfo.AddKey(EKeys::Gamepad_FaceButton_Right);
		ToggleInputInfo.AddKey(EKeys::G);

		Player.RegisterDevInput(ToggleInputInfo);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DebugUserComp.bUsingDebugCamera)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DebugUserComp.bUsingDebugCamera)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Move to current view
		UHazeViewPoint ViewPoint = Player.GetViewPoint();
		FMinimalViewInfo CurrentView;
		ViewPoint.GetViewInfo(CurrentView);

		FHitResult HitResult;
		DebugCamera.SetActorLocation(CurrentView.Location, false, HitResult, true);
		DebugCamera.SetActorRotation(CurrentView.Rotation, true);

		CameraSettings.FOV.Apply(Math::Clamp(CurrentView.FOV, 70.0, 90.0), this, 0, EHazeCameraPriority::Debug);
		Player.ActivateCamera(DebugCamera.Camera, 0, this, EHazeCameraPriority::Debug);

		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, CameraTags::UsableWhileInDebugCamera, this);
		Player.BlockCapabilities(CameraTags::CameraNonControlled, this);
		Player.BlockCapabilities(CameraTags::CameraBlockedByDebugCamera, this);

		bLockView = false;
		HoldSpeedFactor.Value = 1.0;
		HoldSpeedFactor.Velocity = 0.0;
		TapSpeedFactor = 1.0;
		SpeedAttributeFactor = 0.0;

		RebuildWidget();

		if (HasControl())
		{
			DebugCamera.SyncedLocation.Value = DebugCamera.ActorLocation;
			DebugCamera.SyncedRotation.Value = DebugCamera.ActorRotation;
			DebugCamera.SyncedLocation.SnapRemote();
			DebugCamera.SyncedRotation.SnapRemote();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(DebugCamera.Camera);

		if (!bLockView)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}

		Player.UnblockCapabilities(CameraTags::CameraNonControlled, this);
		Player.UnblockCapabilities(CameraTags::CameraBlockedByDebugCamera, this);

		if (Widget != nullptr)
		{
			Player.RemoveWidget(Widget);
			Widget = nullptr;
		}

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (DebugCamera != nullptr)
			DebugCamera.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// The debug camera is never debug time dilated
		const float UndilatedDeltaTime = Time::GetCameraDeltaSeconds(false);

		if (HasControl())
		{
			// Rotate camera
			const FVector2D RotationInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);
			const FRotator RotationDelta = FRotator(
				RotationInput.Y * UndilatedDeltaTime * DebugCamera.TurnRate.Pitch,
				RotationInput.X * UndilatedDeltaTime * DebugCamera.TurnRate.Yaw,
				0.0);

			RotateCamera(RotationDelta);

			// Axis Movement
			ApplyAxisMovement(ActionNames::UI_Up, ActionNames::UI_Down, UndilatedDeltaTime, AxisMovement.X);
			ApplyAxisMovement(ActionNames::UI_Right, ActionNames::UI_Left, UndilatedDeltaTime, AxisMovement.Y);
			ApplyAxisMovement(ActionNames::DebugCameraMoveUp, ActionNames::DebugCameraMoveDown, UndilatedDeltaTime, AxisMovement.Z);

			// Move camera if not locked
			if (!bLockView)
			{
				// Speed multiplier is temporarily changed when increase/decrease is pressed
				float TargetHoldSpeedFactor = 1.0;
				if (SpeedDirection > 0)
					TargetHoldSpeedFactor = DebugCamera.MaxHoldSpeedFactor * SpeedDirectionMultiplier;
				else if (SpeedDirection < 0)
					TargetHoldSpeedFactor = 1.0 / DebugCamera.MaxHoldSpeedFactor;

				HoldSpeedFactor.AccelerateTo(TargetHoldSpeedFactor, .5, UndilatedDeltaTime);

				// Change speed multiplier by the DebugCameraSpeed axis value (e.g. mouse wheel)
				SpeedAttributeFactor += Math::Sign(GetAttributeFloat(AttributeNames::DebugCameraSpeed)) * .2;
				float SpeedFactor = Math::Clamp(HoldSpeedFactor.Value * TapSpeedFactor * (1.0 + SpeedAttributeFactor), .01, 100.0);

				// Use raw movement stick instead of MovementDirection, as that is relative to desiredrotation which is
				// (and should be) unaffected by debug camera
				const FVector2D MovementInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				// Rotate the axis movement to be along global X, Y and Z coordinates, but take camera rotation into account
				// so that AxisMovement.X is applied on the global horizontal axis most aligned with camera forward.
				const FRotator AxisRotation = FRotator(0, Math::RoundToFloat(DebugCamera.ActorRotation.Yaw / 90) * 90, 0);
				const FVector RotatedAxisMovement = AxisRotation.RotateVector(AxisMovement);

				FVector MovementDirection = DebugCamera.ActorRotation.RotateVector(FVector(MovementInput.X, MovementInput.Y, 0.0)) + RotatedAxisMovement;
				FVector MovementDelta = MovementDirection * (DebugCamera.BaseSpeed * SpeedFactor * UndilatedDeltaTime);

				MoveCamera(MovementDelta);
			}

			// The debug camera only follows ref frame deltas
			// But not the frame we activate
			if (ActiveDuration > 0)
			{
				FHazeFollowMovementData FollowData = UCameraFollowMovementFollowDataComponent::Get(Player).CameraFollowMovementData;
				MoveCamera(FollowData.TeleportationDelta);
			}

			// Check where we would end up if we'd teleport the player right now
			FHazeCameraCollisionParams TraceSettings;
			DebugCamera.Camera.InitCameraTraceParams(UserComp, TraceSettings);
			devCheck(TraceSettings.bUseCollision);
			TeleportHit = TraceSettings.QueryTraceSingle(
				DebugCamera.ActorLocation,
				DebugCamera.ActorLocation + (DebugCamera.ActorForwardVector * 100000.0),
				n"DebugCameraTeleportHit");

			// Debug draw subtle indication of where a teleport would place us
			if (TeleportHit.bBlockingHit && TeleportHit.Location.DistSquared(DebugCamera.ActorLocation) > Math::Square(100.0))
				Debug::DrawDebugPoint(TeleportHit.Location, 1.5, FLinearColor(1.0, 0.0, 1.0));

			DebugCamera.SyncedLocation.Value = DebugCamera.ActorLocation;
			DebugCamera.SyncedRotation.Value = DebugCamera.ActorRotation;
		}
		else
		{
			DebugCamera.ActorLocation = DebugCamera.SyncedLocation.Value;
			DebugCamera.ActorRotation = DebugCamera.SyncedRotation.Value;
		}

		if (HasControl())
		{
			if (WasActionStarted(ActionNames::DebugCameraCancel))
			{
				DebugUserComp.bUsingDebugCamera = false;
				Player.ConsumeButtonInputsRelatedTo(ActionNames::DebugCameraCancel);
			}

			if (WasActionStarted(ActionNames::DebugCameraViewLock))
			{
				NetSetViewLocked(!bLockView);
				Player.ConsumeButtonInputsRelatedTo(ActionNames::DebugCameraViewLock);
			}

			if (!bLockView)
			{
				if (WasActionStarted(ActionNames::DebugCameraTeleport) && TeleportHit.bBlockingHit)
				{
					NetTeleportPlayer(Player, TeleportHit.Location, FRotator(0.0, DebugCamera.ActorRotation.Yaw, 0.0));
					Player.ConsumeButtonInputsRelatedTo(ActionNames::DebugCameraTeleport);
				}

				if (WasActionStarted(ActionNames::DebugCameraTeleportBoth) && TeleportHit.bBlockingHit)
				{
					const FVector OtherOffset = DebugCamera.ActorRotation.RotateVector(FVector::RightVector * 100.0);

					NetTeleportPlayer(Player, TeleportHit.Location, FRotator(0.0, DebugCamera.ActorRotation.Yaw, 0.0));
					NetTeleportPlayer(Player.OtherPlayer, TeleportHit.Location + OtherOffset, FRotator(0.0, DebugCamera.ActorRotation.Yaw, 0.0));

					Player.ConsumeButtonInputsRelatedTo(ActionNames::DebugCameraTeleportBoth);
				}

				if (WasActionStarted(ActionNames::DebugCameraDecreaseSpeed))
				{
					DecreaseSpeed();
				}
				else if (IsActioning(ActionNames::DebugCameraDecreaseSpeed) &&
						 Time::GetRealTimeSince(DecreaseSpeedTimeStarted) > .75)
				{
					SpeedDirection = -1;
					SpeedDirectionMultiplier = 1.0;
				}

				if (WasActionStarted(ActionNames::DebugCameraIncreaseSpeed))
				{
					IncreaseSpeed();
				}
				else if (IsActioning(ActionNames::DebugCameraIncreaseSpeed) &&
						 Time::GetRealTimeSince(IncreaseSpeedTimeStarted) > .75)
				{
					SpeedDirection = 1;
					SpeedDirectionMultiplier = 1.0;
				}
			}
		}
	}

	private void ApplyAxisMovement(FName PositiveInput, FName NegativeInput, float UndilatedDeltaTime, float& Movement) const
	{
		float WantedMovement = 0.0;
		if (IsActioning(PositiveInput))
			WantedMovement += 1.0;
		if (IsActioning(NegativeInput))
			WantedMovement -= 1.0;

		float InterpSpeed = 2.0;
		if ((WantedMovement == 0.0) ||
			(WantedMovement > 0.0 && Movement < 0.0) ||
			(WantedMovement < 0.0 && Movement > 0.0))
			InterpSpeed = 5.0;

		Movement = Math::FInterpConstantTo(Movement, WantedMovement, UndilatedDeltaTime, InterpSpeed);
	}

	UFUNCTION(NetFunction)
	void NetTeleportPlayer(AHazePlayerCharacter TeleportPlayer, FVector Location, FRotator Rotation)
	{
		TeleportPlayer.TeleportActor(Location, Rotation, this);
	}

	void MoveCamera(const FVector& DeltaMovement)
	{
		if (DeltaMovement.Size() < SMALL_NUMBER)
			return;
		DebugCamera.ActorLocation += DeltaMovement;
	}

	void RotateCamera(const FRotator& DeltaRotation)
	{
		FRotator NewRotation = DebugCamera.ActorRotation + DeltaRotation;
		NewRotation.Roll = 0.0;
		NewRotation.Pitch = Math::ClampAngle(NewRotation.Pitch, -89.0, 89.0);
		DebugCamera.ActorRotation = NewRotation;
	}

	void IncreaseSpeed()
	{
		TapSpeedFactor = Math::Min(TapSpeedFactor * 2.0, 64.0);
		IncreaseSpeedTimeStarted = Time::RealTimeSeconds;
		SpeedDirection = 0;
		SpeedDirectionMultiplier = 1.0;
	}

	void DecreaseSpeed()
	{
		TapSpeedFactor = Math::Max(TapSpeedFactor * 0.5, 1.0 / 64.0);
		DecreaseSpeedTimeStarted = Time::RealTimeSeconds;
		SpeedDirection = 0;
		SpeedDirectionMultiplier = 1.0;
	}

	UFUNCTION(NetFunction)
	void NetSetViewLocked(bool bLocked)
	{
		if (bLockView == bLocked)
			return;

		bLockView = bLocked;

		if (bLockView)
		{
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		}
		else
		{
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		}

		RebuildWidget();
	}

	UFUNCTION()
	private void HandleToggleDebugCamera()
	{
		if (DebugUserComp == nullptr)
			return;

		DebugUserComp.bUsingDebugCamera = !DebugUserComp.bUsingDebugCamera;
	}

	private void RebuildWidget()
	{
		if (!UserComp.DebugCameraWidgetClass.IsValid())
			return;

		if (Widget == nullptr)
		{
			Widget = Cast<UDebugCameraControlsWidget>(
				Player.AddWidget(UserComp.DebugCameraWidgetClass.Get(), EHazeWidgetLayer::Dev));
		}

		Widget.ClearActions();

		if (UDebugCameraHideLockButtonConsole.Int > 0)
		{
			if (!bLockView)
			{
				Widget.AddAction(ActionNames::DebugCameraViewLock, "Enable View Lock");
				Widget.AddAction(ActionNames::DebugCameraTeleport, "Teleport Player");
				Widget.AddAction(ActionNames::DebugCameraTeleportBoth, "Teleport Both Players");
				Widget.AddAction(ActionNames::DebugCameraCancel, "Cancel");
			}
			else
			{
				Widget.AddAction(ActionNames::DebugCameraViewLock, "Disable View Lock");
				Widget.AddAction(ActionNames::DebugCameraCancel, "Cancel");
			}
		}
	}
}
#endif
