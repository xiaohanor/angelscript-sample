class URemoteHackableTelescopeRobotMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 5;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	AHazePlayerCharacter Player;
	UPlayerMovementComponent PlayerMoveComp;

	UHazeCrumbSyncedVectorComponent SyncedMoveInput;

	const float MoveSpeed = 500.0;
	const float AccelerationPitch = 5.0;

	FQuat FrameDeltaRotation;

	FVector AcceleratedPitchAxis;
	float AcceleratedInputMagnitude;

	bool bNoInputLastFrame;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);

		MoveComp = TelescopeRobot.MoveComp;
		Movement = MoveComp.SetupSteppingMovementData();

		SyncedMoveInput = UHazeCrumbSyncedVectorComponent::GetOrCreate(TelescopeRobot, n"SyncedMoveInput");
		SyncedMoveInput.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!TelescopeRobot.HackableComp.bHacked)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!TelescopeRobot.HackableComp.bHacked)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (TelescopeRobot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = TelescopeRobot.HackableComp.HackingPlayer;
		PlayerMoveComp = UPlayerMovementComponent::Get(Player);
		TelescopeRobot.Velocity = Owner.ActorForwardVector;

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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
			SyncedMoveInput.SetValue(PlayerMoveComp.MovementInput);

		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				float Speed = TelescopeRobot.bExtended ? MoveSpeed * 0.5 : MoveSpeed;

				TelescopeRobot.Velocity = Math::VInterpTo(TelescopeRobot.Velocity, SyncedMoveInput.Value * Speed, DeltaTime, 2.0);
				const FVector DeltaMove = TelescopeRobot.Velocity * DeltaTime;

				Movement.AddDelta(DeltaMove);
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();

				// Rotate with right stick
				float SpeedMultiplier = TelescopeRobot.bExtended ? 0.5 : 2.0;
				float DeltaYaw = GetAttributeVector2D(AttributeVectorNames::RightStickRaw).X;
				FrameDeltaRotation = FQuat(PlayerMoveComp.WorldUp, DeltaYaw * DeltaTime * SpeedMultiplier);
				FQuat Rotation = FrameDeltaRotation * TelescopeRobot.ActorQuat;

				Movement.SetRotation(Rotation);
			}
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
		}

		// Interpolate pitch axis
		FVector InclineAxis = SyncedMoveInput.Value.GetSafeNormal().CrossProduct(PlayerMoveComp.WorldUp).GetSafeNormal();
		InclineAxis = TelescopeRobot.ActorRelativeTransform.InverseTransformVectorNoScale(InclineAxis);
		AcceleratedPitchAxis = Math::VInterpTo(AcceleratedPitchAxis, InclineAxis, DeltaTime, 2.0);

		// Interpolate pitch factor
		AcceleratedInputMagnitude = Math::FInterpTo(AcceleratedInputMagnitude, SyncedMoveInput.Value.Size(), DeltaTime, 3);
		float Pitch = AccelerationPitch * AcceleratedInputMagnitude;
		FQuat AccelerationIncline = FQuat(AcceleratedPitchAxis, Math::DegreesToRadians(Pitch));

		// Set relative rotation; don't rotate rawd
		TelescopeRobot.MeshRoot.SetRelativeRotation(AccelerationIncline);
		TelescopeRobot.TelescopeMesh.SetRelativeRotation(AccelerationIncline.Inverse());

		// Independent from rest of rotation
		AlignWheels(DeltaTime);

		// Finally interpolate camera to actor forward
		float InterpSpeed = TelescopeRobot.bExtended ? 4.0 : 8.0;
		FQuat CameraRotation = FQuat(Player.ViewRotation.RightVector, Math::DegreesToRadians(15)) * FQuat::MakeFromX(TelescopeRobot.MeshRoot.ForwardVector);
		CameraRotation = Math::QInterpTo(Player.ViewRotation.Quaternion(), CameraRotation, DeltaTime, InterpSpeed);
		Player.SetCameraDesiredRotation(CameraRotation.Rotator(), this);

		// Add delicious FF rumble when other player walks on rod
		AHazePlayerCharacter OtherPlayer = Player.OtherPlayer;
		UPlayerPerchComponent OtherPlayerPerchComponent = UPlayerPerchComponent::Get(OtherPlayer);
		if (OtherPlayerPerchComponent.bIsGroundedOnPerchSpline)
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
	}

	void AlignWheels(float DeltaTime)
	{
		if (SyncedMoveInput.Value.IsNearlyZero(0.1))
		{
			// Don't rotate wheel base if there was no input
			TelescopeRobot.WheelRoot.SetWorldRotation(FrameDeltaRotation.Inverse() * TelescopeRobot.WheelRoot.ComponentQuat);
			bNoInputLastFrame = true;
			return;
		}

		// HACK IT! Flip forward to have tank-like base rotation
		FVector ForwardVector = SyncedMoveInput.Value.GetSafeNormal();
		if (SyncedMoveInput.Value.GetSafeNormal().DotProduct(TelescopeRobot.WheelRoot.ForwardVector) < 0. && bNoInputLastFrame)
			TelescopeRobot.WheelRoot.SetWorldRotation(FQuat::MakeFromX(-TelescopeRobot.WheelRoot.ForwardVector));

		// Make rotation and interpolate
		FQuat Rotation = FQuat::MakeFromX(ForwardVector);
		Rotation = Math::QInterpTo(TelescopeRobot.WheelRoot.WorldRotation.Quaternion(), Rotation, DeltaTime, 4);
		TelescopeRobot.WheelRoot.SetWorldRotation(Rotation);

		bNoInputLastFrame = false;
	}
}