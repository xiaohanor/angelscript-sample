
UCLASS(Abstract)
class UWorld_Skyline_InnerCity_Event_AttackShip_Antenna_Crash_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineAttackShip AttackShip;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		AttackShip = Cast<ASkylineAttackShip>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(AttackShip.CrashSpline == nullptr)
			return false;

		if(AttackShip.Spline != AttackShip.CrashSpline)
			return false;

		if(!AttackShip.bIsCrashing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(AttackShip.bIsCrashing)
			return false;

		return true;
	}

	UFUNCTION(BlueprintPure)
	float GetCrashSplineAlpha()
	{
		return AttackShip.Spline.GetClosestSplineDistanceToWorldLocation(AttackShip.ActorLocation) / AttackShip.Spline.SplineLength;
	}
}