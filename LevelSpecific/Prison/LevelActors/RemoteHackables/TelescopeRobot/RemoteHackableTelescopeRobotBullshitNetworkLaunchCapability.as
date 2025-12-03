
// This capability will only run locally on magnet control side (robot's remote)
class URemoteHackableTelescopeRobotBullshitNetworkLaunchCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::BeforeGameplay;

	ARemoteHackableTelescopeRobot TelescopeRobot;

	bool bOffsetUndoDone;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TelescopeRobot = Cast<ARemoteHackableTelescopeRobot>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Network::IsGameNetworked())
			return false;

		if (!TelescopeRobot.bLaunched)
			return false;

		if (TelescopeRobot.bDestroyed)
			return false;

		if (!Drone::GetMagnetDronePlayer().HasControl())
			return false;

		if (TelescopeRobot.IsAnyCapabilityActive(TelescopeRobot::TelescopeRobotLaunchCapability))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TelescopeRobot.bLaunched)
			return true;

		if (TelescopeRobot.bDestroyed)
			return true;

		if (bOffsetUndoDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Juice up
		TelescopeRobot.SuperMeshRoot.SetRelativeLocation(FVector::ZeroVector);

		bOffsetUndoDone = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Start undoing lerp if proper launch capability is active
		if (TelescopeRobot.IsAnyCapabilityActive(TelescopeRobot::TelescopeRobotLaunchCapability))
		{
			FVector RelativeLocation = Math::VInterpConstantTo(TelescopeRobot.SuperMeshRoot.RelativeLocation, FVector::ZeroVector, DeltaTime, 300.0);
			TelescopeRobot.SuperMeshRoot.SetRelativeLocation(RelativeLocation);

			if (TelescopeRobot.SuperMeshRoot.RelativeLocation.IsNearlyZero())
				bOffsetUndoDone = true;
		}
		else
		{
			// Apply fake offset
			float PingMultiplier = Network::PingRoundtripSeconds * 2.0;
			float DurationMultiplier = 1.0 - Math::Square(Math::Saturate(ActiveDuration / PingMultiplier));
			FVector Impulse = TelescopeRobot.ActorUpVector * (800 / (1.0 + PingMultiplier)) * DurationMultiplier;
			FVector RelativeLocation = TelescopeRobot.SuperMeshRoot.RelativeLocation + Impulse * DeltaTime;
			TelescopeRobot.SuperMeshRoot.SetRelativeLocation(RelativeLocation);
		}
	}
}