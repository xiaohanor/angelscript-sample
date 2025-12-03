
UCLASS(Abstract)
class UWorld_Prison_MaxSecurity_LaserHellSplineLaser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AMaxSecurityLaser Laser;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Laser = Cast<AMaxSecurityLaser>(HazeOwner);
		DefaultEmitter.AudioComponent.SetRelativeLocation(FVector(Laser.LaserComp.BeamLength / 2, 0.0, 0.0));
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Spline Alpha"))
	float GetSplineAlpha()
	{
		return Laser.GetCurrentSplineDistance() / Laser.GetSpline().SplineLength;
	}
}