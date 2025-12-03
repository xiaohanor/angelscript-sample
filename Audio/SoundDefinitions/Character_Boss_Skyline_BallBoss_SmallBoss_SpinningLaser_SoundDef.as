
UCLASS(Abstract)
class UCharacter_Boss_Skyline_BallBoss_SmallBoss_SpinningLaser_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASkylineBallBossSmallBoss SmallBoss;	

	UFUNCTION(BlueprintEvent)
	void OnPlayerOverlapPassbyVolume(AHazePlayerCharacter Player) {}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return SmallBoss.bLaserActive;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return !SmallBoss.bLaserActive;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SmallBoss = Cast<ASkylineBallBossSmallBoss>(HazeOwner);
		SmallBoss.LaserPassbyAudioCollisionComp.OnComponentBeginOverlap.AddUFunction(this, n"OnPlayerOverlapLaserPassbyComponent");
	}

	UFUNCTION(BlueprintPure)
	bool IsLaserActive()
	{
		return SmallBoss.bLaserActive;
	}

	UFUNCTION()
	void OnPlayerOverlapLaserPassbyComponent(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in HitResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player == nullptr)
			return;

		OnPlayerOverlapPassbyVolume(Player);
	}
}