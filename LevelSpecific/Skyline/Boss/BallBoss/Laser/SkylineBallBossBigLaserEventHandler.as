class USkylineBallBossBigLaserEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void PreActivateElevatorLaser() {}

	UFUNCTION(BlueprintEvent)
	void ActivateLaser() {}

	UFUNCTION(BlueprintEvent)
	void DeactivateLaser() {}

	UFUNCTION(BlueprintEvent)
	void TelegraphLaser() {}

	UFUNCTION(BlueprintEvent)
	void TraceLaserImpactEnd() {}

	UFUNCTION(BlueprintEvent)
	void FinalLaserActivated() {}
}