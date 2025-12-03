class UCutsceneSwarmDroneMovementResponseComponent : UActorComponent
{
	default SetComponentTickEnabled(false);
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	private FTransform PreviousTransform = FTransform::Identity;

	ACutsceneSwarmDrone SwarmDrone;
	UDroneMovementSettings MovementSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		SwarmDrone = Cast<ACutsceneSwarmDrone>(Owner);
		MovementSettings = UDroneMovementSettings::GetSettings(SwarmDrone);

		PreviousTransform = Owner.ActorTransform;
	}

	void UpdateMovement(FCutsceneSwarmDroneMoveData MoveData)
	{
		if (SwarmDrone == nullptr)
			return;

		if(MoveData.DeltaTime < KINDA_SMALL_NUMBER)
			return;

		// Update velocity
		FVector Velocity = Owner.ActorTransform.Location - PreviousTransform.Location;
		SwarmDrone.SetActorVelocity(Velocity / MoveData.DeltaTime);
		PreviousTransform = Owner.ActorTransform;

		// Update rotation of drone mesh based on velocity
		UpdateMeshRotation(MoveData.DeltaTime);

		// Handle bot transform and anims
		UpdateBots(MoveData.DeltaTime);
	}

	private void UpdateMeshRotation(float DeltaTime)
	{
		const FVector AngularVelocity =  SwarmDrone.ActorVelocity.CrossProduct(FVector::UpVector);
		float RotationSpeed = (AngularVelocity.Size() / SwarmDrone.SwarmDroneVisualRadius);
		RotationSpeed = Math::Clamp(RotationSpeed, -MovementSettings.RollMaxSpeed, MovementSettings.RollMaxSpeed);

		const FQuat DeltaQuat = FQuat(AngularVelocity.GetSafeNormal(), RotationSpeed * DeltaTime * -1);
		SwarmDrone.SwarmGroupMeshComponent.AddWorldRotation(DeltaQuat);
	}

	private void UpdateBots(float DeltaTime)
	{
		// Get the animation that will be used for bots
		EHazeSwarmBotAnimState BotAnimState = GetBotAnimState();

		for (auto& SwarmBot : SwarmDrone.SwarmBots)
		{
			FVector CenterToBot = (SwarmBot.WorldTransform.Location - SwarmDrone.DroneCenter).GetSafeNormal();

			// Shifting rotation
			// Makes it look so that bots in lower back accelerate the ball
			{
				FQuat RotationOffset = FQuat::Identity;

				if (!SwarmDrone.ActorVelocity.IsNearlyZero(20.0))
				{
					float FaceDot = SwarmDrone.ActorVelocity.GetSafeNormal().DotProduct(CenterToBot);
					if (FaceDot < 0)
					{
						float AlingmentMultiplier = Math::Min(CenterToBot.DotProduct(FVector::UpVector), 0.0);
						if (AlingmentMultiplier > -0.8 && AlingmentMultiplier < -0.6)
						{
							float Angle = -20 * Math::Abs(AlingmentMultiplier * 4);
							FVector RotationAxis = SwarmDrone.ActorVelocity.GetSafeNormal();
							RotationAxis = SwarmDrone.ActorVelocity.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

							RotationAxis = RotationAxis.CrossProduct(FVector::UpVector);
							RotationAxis = SwarmBot.WorldTransform.InverseTransformVector(RotationAxis);

							RotationOffset = FQuat(RotationAxis, Math::DegreesToRadians(Angle));
						}
					}
				}

				// Rotate bot to give slate-acceleration appearance
				FQuat Rotation = SwarmBot.OriginalRelativeTransform.Rotation * RotationOffset;
				float AccelerationTime = Math::Min(1.0, 90.0 / Math::Max(SwarmDrone.ActorVelocity.Size(), 0.016));
				SwarmBot.AcceleratedRelativeRotation.AccelerateTo(Rotation, AccelerationTime, DeltaTime);
				SwarmBot.RelativeTransform.SetRotation(SwarmBot.AcceleratedRelativeRotation.Value.GetNormalized());
			}

			// Location offset
			// Makes it so bottom and top are squished together
			{
				FVector Offset = SwarmBot.OriginalRelativeTransform.TransformVectorNoScale(CenterToBot);
				float Alignment = CenterToBot.DotProduct(FVector::UpVector);
				if (Alignment < 0.0)
				{
					Offset *= 15.0 * Math::Abs(Alignment);
				}
				else
				{
					Offset *= Alignment * DeltaTime * 0.5;
				}

				FVector RelativeLocation = SwarmBot.OriginalRelativeTransform.Location + Offset;
				SwarmBot.RelativeTransform.Location = RelativeLocation;
			}

			SwarmBot.AnimData.AnimState = BotAnimState;
		}
	}

	EHazeSwarmBotAnimState GetBotAnimState() const
	{
		// Add more as required
		return EHazeSwarmBotAnimState::Retracted;
	}

	bool IsInitialized() const
	{
		return SwarmDrone != nullptr;
	}
}