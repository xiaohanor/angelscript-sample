class UAutoTurretTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AutoTurretTargeting");

	AAutoTurret AutoTurret;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AutoTurret = Cast<AAutoTurret>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!HasValidTarget())
			return false;
			
		return true;
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AutoTurret.CurrentTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AutoTurret.CurrentTarget = GetTargetInRange();

		PrintToScreen("Target:" + AutoTurret.CurrentTarget);

		FVector AimDirection = AutoTurret.CurrentTarget.ActorCenterLocation - AutoTurret.Pivot.WorldLocation; // Actor focus location
	
		FRotator AimRotation = Math::RInterpTo(AutoTurret.Pivot.WorldRotation, FRotator::MakeFromX(AimDirection), DeltaTime, 5.0);

		AutoTurret.Pivot.SetWorldRotation(AimRotation);

	}

	bool HasValidTarget() const
	{

		return (GetTargetInRange() != nullptr);

	}

	AHazeActor GetTargetInRange() const
	{
		AHazeActor ClosestTarget;
		float ClosestDistance = AutoTurret.Range;

		for (auto Target : AutoTurret.Targets) 
		{
			float DistanceToTarget = Target.GetDistanceTo(AutoTurret);

			if (DistanceToTarget < ClosestDistance)
			{
				ClosestDistance = DistanceToTarget;
				ClosestTarget = Target;
			}

		}

		return ClosestTarget;

	}

}