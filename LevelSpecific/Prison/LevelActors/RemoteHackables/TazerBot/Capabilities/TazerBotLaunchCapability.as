namespace TazerBot
{
	const FName TazerBotLaunchCapability = n"TazerBotLaunchCapability";
}

struct FTazerBotLaunchCapabilityActivationParams
{
	// Used with a controlled targeted launch
	FTazerBotLaunchParams LaunchParams;
}

class UTazerBotLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(TazerBot::TazerBotLaunchCapability);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 3;

	ATazerBot TazerBot;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FTazerBotLaunchParams LaunchParams;

	FVector2D RandomTorque;

	bool bTumbling;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);

		MovementComponent = TazerBot.MovementComponent;
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTazerBotLaunchCapabilityActivationParams& ActivationParams) const
	{
		if (!TazerBot.bLaunched)
			return false;

		if (TazerBot.bDestroyed)
			return false;

		ActivationParams.LaunchParams = TazerBot.CurrentLaunchParams;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.bLaunched)
			return true;

		if (MovementComponent.IsOnWalkableGround())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FTazerBotLaunchCapabilityActivationParams ActivationParams)
	{
		LaunchParams = ActivationParams.LaunchParams;
		RandomTorque = LaunchParams.RandomTorque;

		TazerBot.SetActorVelocity(LaunchParams.Impulse);

		bTumbling = false;

		if (TazerBot.IsHacked())
			TazerBot.HackingPlayer.ApplyCameraSettings(TazerBot.LaunchCameraSettings, 0.2, this, EHazeCameraPriority::High);

		UTazerBotEventHandler::Trigger_OnLaunched(TazerBot);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TazerBot.bLaunched = false;

		// Don't send network stuff when getting destroyed
		if (TazerBot.HasActorBegunPlay())
		{
			// Movement world can be altered when we deactivate, force up vector
			FRotator Rotation = FRotator::MakeFromXZ(MovementComponent.HorizontalVelocity.ConstrainToPlane(FVector::UpVector), FVector::UpVector);
			TazerBot.SmoothTeleportActor(TazerBot.ActorLocation, Rotation, this);
		}

		TazerBot.MeshOffsetComponent.ResetOffsetWithLerp(this, 0.2);

		// Juice
		if (TazerBot.IsHacked())
		{
			TazerBot.HackingPlayer.PlayForceFeedback(TazerBot.LaunchLandingFF, false, false, this);
			TazerBot.HackingPlayer.PlayCameraShake(TazerBot.LaunchLandingCamShake, this);
		}

		TazerBot.HackingPlayer.ClearCameraSettingsByInstigator(this, 2.0);

		if(!TazerBot.bDestroyed && !TazerBot.bRespawning)
			UTazerBotEventHandler::Trigger_OnLandedAfterLaunch(TazerBot);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if (!bTumbling)
			{
				if(IsTumbling())
				{
					bTumbling = true;
					UTazerBotEventHandler::Trigger_OnTumblingAfterLaunch(TazerBot);

					// Play camera shake
					if (TazerBot.IsHacked())
						TazerBot.HackingPlayer.PlayCameraShake(TazerBot.LaunchTumbleCamShake, this);
				}
			}

			if (HasControl())
			{
				// Add velocity
				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();

				// Das rite, add extra gravity when tumbling around
				if(bTumbling)
					MoveData.AddGravityAcceleration();

				MoveData.AddHorizontalVelocity(MovementComponent.HorizontalVelocity);

				if (bTumbling)
				{
					FVector Drag = -MovementComponent.HorizontalVelocity * DeltaTime * 5.0;
					MoveData.AddHorizontalVelocity(Drag);
				}

				// Add rotation
				FQuat Rotation = FQuat::MakeFromXZ(MovementComponent.Velocity.ConstrainToPlane(MovementComponent.WorldUp), MovementComponent.WorldUp);
				MoveData.InterpRotationTo(Rotation, 5, false);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);

			// Rotate mesh...
			// We know how far away target is, so we have air time
			// Rotate bot 360 degrees on its pitch axis
			if (IsTargetedLaunch())
			{
				// Start aggressively and then slow rotation down
				float Exp = 0.5;
				float SpeedMultiplier = 1.1;
				float Progress = Math::Pow(Math::Saturate((ActiveDuration * SpeedMultiplier) / (LaunchParams.Time - 0.1)), Exp);
				FQuat MeshRotation = FQuat(TazerBot.ActorRightVector, PI * 2.0 * Progress) * TazerBot.ActorQuat;
				TazerBot.MeshOffsetComponent.LerpToRotation(this, MeshRotation, 0.1);

			}

			// Launch without specific target...
			// maybe do something more intricate? Like handling mid-air collisions
			else
			{
				float Multiplier = bTumbling ? 2.5 : 1.0;
				FQuat DeltaRotation = FQuat(-TazerBot.ActorRightVector, RandomTorque.X * DeltaTime * Multiplier);
				FQuat MeshRotation = DeltaRotation * TazerBot.MeshOffsetComponent.ComponentQuat;
				TazerBot.MeshOffsetComponent.LerpToRotation(this, MeshRotation, 0.1);
			}

			// Do force feedback stuff
			if (bTumbling && TazerBot.IsHacked())
			{
				FHazeFrameForceFeedback FF;
				FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(ActiveDuration));
				FF.RightMotor = Math::Abs(Math::PerlinNoise1D(ActiveDuration * 1.618));
				TazerBot.HackingPlayer.SetFrameForceFeedback(FF, 0.2);
			}

			if(MovementComponent.HasImpactedWall())
				UTazerBotEventHandler::Trigger_OnImpact(TazerBot);
		}
	}

	bool IsTargetedLaunch() const
	{
		return LaunchParams.Time != 0.0;
	}

	bool IsTumbling() const
	{
		if (Math::IsNearlyZero(ActiveDuration))
			return false;

		if (!MovementComponent.GroundContact.bBlockingHit)
			return false;

		return MovementComponent.GroundContact.Type != EMovementImpactType::Ground;
	}
}