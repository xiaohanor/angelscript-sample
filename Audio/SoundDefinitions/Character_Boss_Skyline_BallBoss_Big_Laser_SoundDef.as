
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_Big_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DeactivateLaser(){}

	UFUNCTION(BlueprintEvent)
	void ActivateLaser(){}

	UFUNCTION(BlueprintEvent)
	void TelegraphLaser(){}

	UFUNCTION(BlueprintEvent)
	void TraceLaserImpactEnd(){}

	UFUNCTION(BlueprintEvent)
	void FinalLaserActivated(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBallBossBigLaser BigLaser;

	TArray<FAkSoundPosition> LaserSoundPositions;
	default LaserSoundPositions.SetNum(2);

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BigLaser.BallBoss.GetPhase() == ESkylineBallBossPhase::Chase
		|| BigLaser.BallBoss.GetPhase() == ESkylineBallBossPhase::PostChaseElevator)
			return false;

		if(!BigLaser.bActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BigLaser.bActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BigLaser = Cast<ASkylineBallBossBigLaser>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto Player : Game::GetPlayers())
		{
			FVector LaserPlayerPos;
			BigLaser.CollisionComp.GetClosestPointOnCollision(Player.ActorCenterLocation, LaserPlayerPos);

			LaserSoundPositions[int(Player.Player)].SetPosition(LaserPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LaserSoundPositions);		
	}
}