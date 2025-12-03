class USummitDominoCatapultRollRotateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASummitDominoCatapult Catapult;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Catapult = Cast<ASummitDominoCatapult>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Catapult.TimeLastHitByRoll);
		if(TimeSinceLastHitByRoll > Catapult.TimeToCompleteRotation)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		float TimeSinceLastHitByRoll = Time::GetGameTimeSince(Catapult.TimeLastHitByRoll);
		if(TimeSinceLastHitByRoll > Catapult.TimeToCompleteRotation)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Catapult.YawRotationPivot.RelativeRotation = Catapult.TargetQuat.Rotator();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TimeSinceHit = Time::GetGameTimeSince(Catapult.TimeLastHitByRoll);
		float AlphaTime = TimeSinceHit / Catapult.TimeToCompleteRotation;
		float AlphaToReachTarget = Catapult.RollRotationCurve.GetFloatValue(AlphaTime);

		if(Math::IsNearlyEqual(AlphaToReachTarget, 1.0))
			AlphaToReachTarget = 1.0;

		Catapult.YawRotationPivot.RelativeRotation = FQuat::Slerp(Catapult.StartQuat, Catapult.TargetQuat, AlphaToReachTarget).Rotator();
	}
};