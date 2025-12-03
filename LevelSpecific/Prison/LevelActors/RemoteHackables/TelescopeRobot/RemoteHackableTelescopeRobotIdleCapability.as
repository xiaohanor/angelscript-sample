class URemoteHackableTelescopeRobotIdleCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(PrisonTags::Prison);
	
	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 5;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	UHazeMovementComponent MoveComp;
	USteppingMovementData MoveData;

	float IdleMoveSpeed = 200;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);

		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(TelescopeRobot.HackableComp.bHacked)
			return false;

		if (MoveComp.HasMovedThisFrame())
			return false;

		if (TelescopeRobot.bRespawning)
			return false;

		if (TelescopeRobot.bLaunched)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TelescopeRobot.HackableComp.bHacked)
			return true;

		if (MoveComp.HasMovedThisFrame())
			return true;

		if (TelescopeRobot.bRespawning)
			return true;

		if (TelescopeRobot.bLaunched)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TelescopeRobot.AttachParentActor == nullptr && MoveComp.PrepareMove(MoveData))
		{
			if(HasControl())
			{
				// Add horizontal drag
				FVector HorizontalDrag = -MoveComp.HorizontalVelocity * 1.5 * DeltaTime;
				MoveData.AddHorizontalVelocity(HorizontalDrag);

				// Add vertical
				MoveData.AddOwnerVelocity();
				MoveData.AddGravityAcceleration();
			}
			else
			{
				MoveData.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(MoveData);

			// Lerp juicy move rotation back to origin
			FRotator RelativeMeshJuiceRotation = Math::RInterpTo(TelescopeRobot.MeshRoot.RelativeRotation, FRotator::ZeroRotator, DeltaTime, 3);
			TelescopeRobot.MeshRoot.SetRelativeRotation(RelativeMeshJuiceRotation);
		}
	}
}