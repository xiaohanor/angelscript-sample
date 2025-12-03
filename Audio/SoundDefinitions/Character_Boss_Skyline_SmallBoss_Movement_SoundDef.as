
UCLASS(Abstract)
class UCharacter_Boss_Skyline_SmallBoss_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void MioHitSmallBoss(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	ASkylineBallBossSmallBoss SmallBoss;

	const float MAX_ROLLING_SPEED = 2000.0;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(HazeOwner);
	}

	UFUNCTION(BlueprintPure)
	float GetMetalAlpha()
	{
		return float(SmallBoss.SegmentCurrentQuantity) / float(SmallBoss.SegmentQuantity);
	}

	UFUNCTION(BlueprintPure)
	float GetRollingSpeed()
	{
		return Math::Saturate(SmallBoss.ActualRollSpeed / MAX_ROLLING_SPEED);
	}

	UFUNCTION(BlueprintPure)
	float GetIsGroundedValue()
	{
		return SmallBoss.RollRoot.RelativeLocation.Z == 0 ? 1.0 : 0.0;
	}

}