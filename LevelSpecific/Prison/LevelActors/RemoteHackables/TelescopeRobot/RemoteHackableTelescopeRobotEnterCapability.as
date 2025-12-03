// This capability will start orienting robot to initial player camera forward while player launches
class URemoteHackableTelescopeRobotEnterCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeMovement;

	default CapabilityTags.Add(PrisonTags::Prison);
	default TickGroupOrder = 4;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	FVector PlayerCameraForward;

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
		if (!TelescopeRobot.bPlayerHackLaunching)
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// Deactivate when player reaches hackable
		if (TelescopeRobot.HackableComp.bHacked)
			return true;

		if (TelescopeRobot.bDestroyed)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PlayerCameraForward = TelescopeRobot.HackableComp.HackingPlayer.ViewRotation.ForwardVector.ConstrainToPlane(MovementComponent.WorldUp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TelescopeRobot.bPlayerHackLaunching = false;

		// Save wheel world rotation (restore after snap)
		FQuat WheelQuat = TelescopeRobot.WheelRoot.ComponentQuat;

		// Snap actor's rotation to mesh rotation
		TelescopeRobot.TeleportActor(TelescopeRobot.ActorLocation, TelescopeRobot.MeshRoot.WorldRotation, this);
		TelescopeRobot.MeshRoot.SetRelativeRotation(FQuat::Identity);
		TelescopeRobot.WheelRoot.SetWorldRotation(WheelQuat);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ForwardVector = TelescopeRobot.HackableComp.HackingPlayer.ViewRotation.ForwardVector.ConstrainToPlane(MovementComponent.WorldUp);

		FQuat TargetRotation = FQuat::MakeFromX(ForwardVector);
		float InterpSpeed = TelescopeRobot.PlayerHackLaunchParams.LaunchSpeed * DeltaTime * 0.05;
		FQuat Rotation = Math::QInterpTo(TelescopeRobot.MeshRoot.WorldRotation.Quaternion(), TargetRotation, DeltaTime, InterpSpeed);

		// Rotate mesh only
		TelescopeRobot.MeshRoot.SetWorldRotation(Rotation);
	}
}