class UCutsceneSwarmDroneBotMovementCapability : UHazeCapability
{
	// Tick after mesh rotation
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 150;

	ACutsceneSwarmDrone SwarmDrone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwarmDrone = Cast<ACutsceneSwarmDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
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
				float AccelerationTime = Math::Min(1.0, 90.0 / Math::Max(SwarmDrone.ActorVelocity.Size(), DeltaTime));
				SwarmBot.AcceleratedRelativeRotation.AccelerateTo(Rotation, AccelerationTime, DeltaTime);
				SwarmBot.RelativeTransform.SetRotation(SwarmBot.AcceleratedRelativeRotation.Value);
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
}