
UCLASS(Abstract)
class UGameplay_Character_Boss_Skyline_BossTank_MortarBall_Projectile_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnExplode(FSkylineBossTankMortarBallOnExplodeEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnImpact(FSkylineBossTankMortarBallOnImpactEventData EventData){}

	UFUNCTION(BlueprintEvent)
	void OnFired(FSkylineBossTankMortarBallOnFiredEventData EventData){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineBossTankMortarBall MortarBall;
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MortarBall = Cast<ASkylineBossTankMortarBall>(HazeOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Projectile Travel Alpha"))
    float GetProjectileTravelAlpha()
    {
        const float DistSqrd = MortarBall.LaunchTrajectory.LaunchLocation.DistSquared(MortarBall.LaunchTrajectory.LandLocation);

		return Math::GetMappedRangeValueClamped(FVector2D(DistSqrd, 0.0), FVector2D(0.0, 1.0), MortarBall.ActorLocation.DistSquared(MortarBall.LaunchTrajectory.LandLocation));
    }

}