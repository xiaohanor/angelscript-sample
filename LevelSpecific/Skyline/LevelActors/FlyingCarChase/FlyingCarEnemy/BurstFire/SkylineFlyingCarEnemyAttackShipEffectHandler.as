struct FSkylineFlyingCarEnemyBurstFireTelegraphingParams
{
	FSkylineFlyingCarEnemyBurstFireTelegraphingParams(FVector InLeftMuzzleLocation, FVector InRightMuzzleLocation, FVector TurretLocation, USkylineFlyingCarEnemyTrackingLaserComponent& LaserComp, UBasicAIProjectileLauncherComponent& _LeftLauncherComp, UBasicAIProjectileLauncherComponent& _RightLauncherComp)
	{
		LeftMuzzleLocation = InLeftMuzzleLocation;
		RightMuzzleLocation = InRightMuzzleLocation;
		TurretActorLocation = TurretLocation;
		TrackLaserComp = LaserComp;
		LeftLauncherComp = _LeftLauncherComp;
		RightLauncherComp = _RightLauncherComp;
	}

	UPROPERTY()
	FVector LeftMuzzleLocation;

	UPROPERTY()
	FVector RightMuzzleLocation;
	
	UPROPERTY()
	FVector TurretActorLocation;

	UPROPERTY()
	USkylineFlyingCarEnemyTrackingLaserComponent TrackLaserComp;
	
	UPROPERTY()
	UBasicAIProjectileLauncherComponent LeftLauncherComp;
	
	UPROPERTY()
	UBasicAIProjectileLauncherComponent RightLauncherComp;
}


UCLASS(Abstract)
class USkylineFlyingCarEnemyAttackShipEffectHandler : UHazeEffectEventHandler
{    
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphingTrackingLaser(FSkylineFlyingCarEnemyBurstFireTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStartTelegraphing(FSkylineFlyingCarEnemyBurstFireTelegraphingParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnStopTelegraphing() {}

	// Deprecated, replaced by using OnLaunch in Projectile effect handler.
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBurstFireLaunch() {}
}