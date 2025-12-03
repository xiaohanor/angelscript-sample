class UFerrisWindmillActivatorRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	AFerrisWindmillActivator Windmill;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Windmill = Cast<AFerrisWindmillActivator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Windmill.TimeLastHitByRoll);
		// if(TimeSinceLastHitByRoll > Windmill.TimeToCompleteRotation)
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Windmill.TimeLastHitByRoll);
		// if(TimeSinceLastHitByRoll > Windmill.TimeToCompleteRotation)
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Windmill.YawRotationPivot.RelativeRotation = Windmill.TargetQuat.Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// float TimeSinceHit = Time::GetGameTimeSince(Windmill.TimeLastHitByRoll);
		// float AlphaTime = TimeSinceHit / Windmill.TimeToCompleteRotation;
		// float AlphaToReachTarget = Windmill.RollRotationCurve.GetFloatValue(AlphaTime);

		// if(Math::IsNearlyEqual(AlphaToReachTarget, 1.0))
		// 	AlphaToReachTarget = 1.0;

		// Windmill.YawRotationPivot.RelativeRotation = FQuat::Slerp(Windmill.StartQuat, Windmill.TargetQuat, AlphaToReachTarget).Rotator();
	}
};