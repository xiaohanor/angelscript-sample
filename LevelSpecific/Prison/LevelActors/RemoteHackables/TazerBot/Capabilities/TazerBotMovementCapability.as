class UTazerBotMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ATazerBot TazerBot;

	UHazeMovementComponent MovementComponent;
	USweepingMovementData MoveData;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent PlayerMovementComponent;

	UHazeCrumbSyncedVectorComponent SyncedMoveInput;

	const float AccelerationPitch = 3.0;

	// Used to ease in camera control when capability activates
	const float CameraControlEaseInDuration = 0.3;

	FQuat FrameDeltaRotation;
	FVector AcceleratedPitchAxis;
	float AcceleratedInputMagnitude;

	bool bNoInputLastFrame;

	float TracksOffset;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSweepingMovementData();

		SyncedMoveInput = UHazeCrumbSyncedVectorComponent::GetOrCreate(TazerBot, n"SyncedMoveInput");
		SyncedMoveInput.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.IsHacked())
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (TazerBot.bDestroyed)
			return false;

		if (!MovementComponent.IsOnAnyGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.IsHacked())
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		if (!MovementComponent.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = TazerBot.HackingPlayer;
		PlayerMovementComponent = UPlayerMovementComponent::Get(Player);

		// Eman TODO: Handle in a special landing capability with more juice
		// Chilldown when coming from a jump
		TazerBot.SetActorVelocity(TazerBot.ActorVelocity * 0.1);

		AcceleratedInputMagnitude = 0.0;
		FrameDeltaRotation = FQuat::Identity;

		SyncedMoveInput.SetValue(FVector::ZeroVector);

		Player.BlockCapabilities(CameraTags::CameraControl, this);
		Player.BlockCapabilities(CameraTags::CameraChaseAssistance, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		Player.UnblockCapabilities(CameraTags::CameraChaseAssistance, this);

		Player = nullptr;
		PlayerMovementComponent = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
			SyncedMoveInput.SetValue(PlayerMovementComponent.MovementInput);

		if (MovementComponent.PrepareMove(MoveData))
		{
			FVector BaseForward = RotateBaseAndGetForward(DeltaTime);

			if (HasControl())
			{
				float TargetSpeed = Math::Lerp(TazerBot.Settings.MoveSpeed, TazerBot.Settings.PoleExtendedMoveSpeed, TazerBot.GetRodExtensionFraction());
				float InterpSpeed = Math::IsNearlyZero(SyncedMoveInput.Value.Size()) ? 8.0 : 2.0;

				float Speed = Math::FInterpTo(TazerBot.ActorVelocity.Size(), SyncedMoveInput.Value.Size() * TargetSpeed, DeltaTime, InterpSpeed);
				FVector Velocity = BaseForward * Speed;

				FVector HorizontalVelocity = Velocity.ConstrainToPlane(TazerBot.MovementWorldUp);
				const FVector DeltaMove = HorizontalVelocity * DeltaTime;

				MoveData.AddDelta(DeltaMove);
				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				auto CameraUser = UCameraUserComponent::Get(Player);
				FVector2D AxisInput = Player.GetCameraInput();

				// Don't allow pitching the camera
				AxisInput.Y = 0.0;

				// Magic constant chosen so sensitivity at default settings is the same as it was before
				// when the sensitivity was hardcoded and didn't respect the options menu
				float SensitivityFactor = TazerBot.Settings.CurrentTurretRotationSpeed / 3.77;

				FRotator DeltaRotation = CameraUser.CalculateBaseDeltaRotationFromSensitivity(AxisInput, DeltaTime, SensitivityFactor);
				FrameDeltaRotation = DeltaRotation.Quaternion();

				FQuat Rotation = FrameDeltaRotation * TazerBot.ActorQuat;
				MoveData.SetRotation(Rotation);

				TazerBot.CrumbedAngularSpeed.SetValue(Math::Abs(DeltaRotation.Yaw));
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			// Don't rotate mesh with actor, handle base rotation separately
			TazerBot.MeshRoot.SetRelativeRotation(TazerBot.ActorQuat.Inverse());

			MoveData.UseGroundStickynessThisFrame();
			MovementComponent.ApplyMove(MoveData);
		}

		// Interpolate pitch axis
		FVector InclineAxis = SyncedMoveInput.Value.GetSafeNormal().CrossProduct(MovementComponent.WorldUp).GetSafeNormal();
		InclineAxis = TazerBot.ActorRelativeTransform.InverseTransformVectorNoScale(InclineAxis);
		AcceleratedPitchAxis = Math::VInterpTo(AcceleratedPitchAxis, InclineAxis, DeltaTime, 2.0);

		// Interpolate pitch factor
		AcceleratedInputMagnitude = Math::FInterpTo(AcceleratedInputMagnitude, SyncedMoveInput.Value.Size(), DeltaTime, 3);
		float Pitch = AccelerationPitch * AcceleratedInputMagnitude;
		FQuat AccelerationIncline = FQuat(AcceleratedPitchAxis, Math::DegreesToRadians(Pitch));

		// Add juicy momentum sway to turret; negate rod rotation in telescope capability
		FQuat HeadRotation = TazerBot.ActorQuat * AccelerationIncline;
		TazerBot.MeshComponent.SetBoneRotationByName(n"Head", HeadRotation.Rotator(), EBoneSpaces::ComponentSpace);

		// Eman TODO: Did this to ensure camera will only get touched once bot has
		// stopped tumbling after a launch. Handle extra time on launch capability instead.
		if (TazerBot.MeshOffsetComponent.RelativeRotation.IsNearlyZero())
		{
			// Finally interpolate camera to actor forward
			float InterpSpeed = TazerBot.bExtended ? 4.0 : 8.0;
			float EaseInAlpha = Math::Square(Math::Saturate(ActiveDuration / CameraControlEaseInDuration));

			FRotator TurretRotation = TazerBot.MeshComponent.GetBoneRotationByName(n"Head", EBoneSpaces::WorldSpace);

			FQuat TargetCameraRotation = FQuat(Player.ViewRotation.RightVector, Math::DegreesToRadians(15)) * FQuat::MakeFromX(TurretRotation.Vector());
			TargetCameraRotation = Math::QInterpTo(Player.ViewRotation.Quaternion(), TargetCameraRotation, DeltaTime, InterpSpeed);

			// Blend-in desired rotation
			FQuat CameraRotation = FQuat::FastLerp(Player.ViewRotation.Quaternion(), TargetCameraRotation, EaseInAlpha);
			Player.SetCameraDesiredRotation(CameraRotation.Rotator(), this);
		}

		// Eman TODO: Move to another capability
		// Add delicious FF rumble when other player walks on rod
		AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
		if (TazerBot.IsPlayePerchingOnTelescope(OtherPlayer))
		{
			// Check if player is moving
			float Speed = OtherPlayer.ActorVelocity.Size();
			if (!Math::IsNearlyZero(Speed))
			{
				UPlayerPerchSettings PerchSettings = UPlayerPerchSettings::GetSettings(OtherPlayer);
				float MaxSpeed = PerchSettings.MaxSpeed - PerchSettings.MinSpeed;
				float Intensity = Math::Saturate(Speed / MaxSpeed);
				float Value = Math::Max(0.0, Math::Sin(ActiveDuration * Speed * 0.09));
				if (Value >= 0.3)
				{
					FHazeFrameForceFeedback ForceFeedback;
					ForceFeedback.LeftTrigger = 0.1;
					ForceFeedback.LeftMotor = 0.1;
					Player.SetFrameForceFeedback(ForceFeedback, Intensity);
				}
			}
		}

		// Move tracks material to reflect speed
		TracksOffset += DeltaTime * Math::Saturate(MovementComponent.Velocity.Size() / TazerBot.Settings.MoveSpeed) * 12.0;
		TazerBot.TracksMaterialInstance.SetScalarParameterValue(n"OffsetY", TracksOffset);
	}

	// This will rotate whole mesh (base is highest in the bone hierarchy)
	FVector RotateBaseAndGetForward(float DeltaTime)
	{
		FQuat BaseRotation = TazerBot.MeshComponent.GetBoneRotationByName(n"Base", EBoneSpaces::WorldSpace).Quaternion();

		if (SyncedMoveInput.Value.IsNearlyZero(0.1))
		{
			// Don't rotate wheel base if there was no input
			TazerBot.MeshRoot.SetWorldRotation(FrameDeltaRotation.Inverse() * TazerBot.MeshRoot.ComponentQuat);
			bNoInputLastFrame = true;

			return BaseRotation.ForwardVector;
		}

		FVector ForwardVector = SyncedMoveInput.Value.GetSafeNormal();

		//  Flip forward to have tank-like base rotation
		FQuat Multiplier = FQuat::Identity;
		// if (SyncedMoveInput.Value.GetSafeNormal().DotProduct(BaseRotation.ForwardVector) < 0. /*&& bNoInputLastFrame*/)
		// 	Multiplier = FQuat(TazerBot.MovementWorldUp, Math::DegreesToRadians(180.0));

		// Make rotation and interpolate
		FQuat TargetRotation = Multiplier * FQuat::MakeFromX(ForwardVector);
		BaseRotation = Math::QInterpTo(BaseRotation, TargetRotation, DeltaTime, 3.5); // 4.0

		// Add some road noise
		float SpeedFraction = Math::Saturate(MovementComponent.Velocity.Size() / TazerBot.Settings.MoveSpeed);
		float PitchNoise = Math::PerlinNoise1D(Time::GameTimeSeconds * 1.63) * 0.2 * SpeedFraction;
		float RollNoise = Math::PerlinNoise1D(Time::GameTimeSeconds * 0.6) * 0.2 * SpeedFraction;

		FQuat NoisyBaseRotation = FQuat(BaseRotation.RightVector, Math::DegreesToRadians(PitchNoise)) * FQuat(BaseRotation.ForwardVector, Math::DegreesToRadians(RollNoise)) * BaseRotation;
		TazerBot.MeshComponent.SetBoneRotationByName(n"Base", NoisyBaseRotation.Rotator(), EBoneSpaces::WorldSpace);

		return BaseRotation.ForwardVector;
	}
}