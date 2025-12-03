
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_Chase_Laser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void DeactivateLaser(){}

	UFUNCTION(BlueprintEvent)
	void ActivateLaser(){}

	UFUNCTION(BlueprintEvent)
	void PreActivateElevatorLaser(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ASkylineBallBossBigLaser BigLaser;

	TArray<FAkSoundPosition> LaserSoundPositions;
	default LaserSoundPositions.SetNum(2);

	UFUNCTION(BlueprintEvent)
	void OnReturnToChaseSpline () {}

	UFUNCTION(BlueprintEvent)
	void OnDemolishCarsLaserSweep () {}

	private int EventSplineIndex = 0;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(BigLaser.BallBoss.GetPhase() == ESkylineBallBossPhase::Chase)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(BigLaser.BallBoss.GetPhase() != ESkylineBallBossPhase::Chase)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		BigLaser = Cast<ASkylineBallBossBigLaser>(HazeOwner);
		BigLaser.BallBoss.OnChaseLaserSplineChanged.AddUFunction(this, n"OnChaseSplineChanged");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(!BigLaser.bActive)
			return;

		for(auto Player : Game::GetPlayers())
		{
			FVector LaserPlayerPos;
			BigLaser.CollisionComp.GetClosestPointOnCollision(Player.ActorCenterLocation, LaserPlayerPos);

			LaserSoundPositions[int(Player.Player)].SetPosition(LaserPlayerPos);
		}

		DefaultEmitter.AudioComponent.SetMultipleSoundPositions(LaserSoundPositions);
	}

	UFUNCTION()
	void OnChaseSplineChanged()
	{
		if(!BigLaser.BallBoss.EventSplineID.IsNone())	
		{
			switch(EventSplineIndex)
			{
				case(0): OnDemolishCarsLaserSweep(); break;
				default: break;

			}

			++EventSplineIndex;
		}
		else
			OnReturnToChaseSpline();
	}		

}