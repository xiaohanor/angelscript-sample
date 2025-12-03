// Eman TODO: OMG so temp
class URemoteHackableTelescopeRobotLandFlipCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 2;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TelescopeRobot.bDestroyed)
			return false;

		if (!TelescopeRobot.bLaunched)
			return false;

		if (!MovementComponent.WasInAir())
			return false;

		if (!MovementComponent.IsOnWalkableGround())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > 1)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Add little upwards impulse
		FVector Impulse = TelescopeRobot.MovementWorldUp * 600.0;
		TelescopeRobot.SetActorVelocity(Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			if(HasControl())
			{
				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddVerticalAcceleration(MovementComponent.Gravity * 2);

				FVector ForwardVector = TelescopeRobot.HackableComp.HackingPlayer.ViewRotation.ForwardVector.ConstrainToPlane(MovementComponent.WorldUp);
				FQuat TargetRotation = FQuat::MakeFromXZ(ForwardVector, MovementComponent.WorldUp);

				float Alpha = Math::Saturate(ActiveDuration / 0.8);

				FQuat Rotation = FQuat::Slerp(TelescopeRobot.ActorQuat, TargetRotation, Alpha);
				MoveData.SetRotation(Rotation);
			}
			else
			{
				MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}
}