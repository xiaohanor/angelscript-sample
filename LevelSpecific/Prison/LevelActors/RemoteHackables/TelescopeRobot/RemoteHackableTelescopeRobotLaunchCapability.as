namespace TelescopeRobot
{
	const FName TelescopeRobotLaunchCapability = n"TelescopeRobotLaunchCapability";
}

struct FRemoteHackableTelescopeRobotLaunchCapabilityActivationParams
{
	FVector2D Torque;
}

class URemoteHackableTelescopeRobotLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(TelescopeRobot::TelescopeRobotLaunchCapability);
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 3;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	UHazeMovementComponent MoveComp;
	USteppingMovementData Movement;

	FVector2D Torque;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FRemoteHackableTelescopeRobotLaunchCapabilityActivationParams& ActivationParams) const
	{
		if (!TelescopeRobot.bLaunched)
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		// Randomize torque
		ActivationParams.Torque = FVector2D(Math::RandRange(1.5, 4.0) * (Math::RandRange(0, 1) == 0 ? 1.0 : -1.0), Math::RandRange(1.5, 4.0) * (Math::RandRange(0, 1) == 0 ? 1.0 : -1.0));
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TelescopeRobot.bLaunched)
			return true;

		if (MoveComp.IsOnAnyGround())
			return true;

		if (TelescopeRobot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FRemoteHackableTelescopeRobotLaunchCapabilityActivationParams ActivationParams)
	{
		Torque = ActivationParams.Torque;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TelescopeRobot.bLaunched = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.AddOwnerVerticalVelocity();
				Movement.AddGravityAcceleration();
				Movement.AddHorizontalVelocity(MoveComp.HorizontalVelocity);

				// Add rotation
				FQuat DeltaRotation = FQuat(-TelescopeRobot.ActorRightVector, Torque.X * DeltaTime) * FQuat(TelescopeRobot.ActorUpVector, Torque.Y * DeltaTime);
				Movement.SetRotation(DeltaRotation * TelescopeRobot.ActorQuat);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
}