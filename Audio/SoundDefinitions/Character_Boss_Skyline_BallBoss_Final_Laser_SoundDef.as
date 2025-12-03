
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_Final_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void FinalLaserActivated(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBallBossFinalLaser FinalLaser;

	TArray<FAkSoundPosition> LaserSoundPositions;
	default LaserSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FinalLaser = Cast<ASkylineBallBossFinalLaser>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(FinalLaser.BallBoss.GetPhase() == ESkylineBallBossPhase::TopMioInKillWeakpoint)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(FinalLaser.BallBoss.GetPhase() == ESkylineBallBossPhase::TopSmallBoss)
			return true;

		return false;
	}

}