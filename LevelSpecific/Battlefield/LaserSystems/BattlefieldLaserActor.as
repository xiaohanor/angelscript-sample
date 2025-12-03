class ABattlefieldLaserActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UBattlefieldLaserComponent LaserComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(2.0));
#endif

	UFUNCTION()
	void ActivateSetTargetFire(AActor KillTarget, float FireTime)
	{
		LaserComp.SetLaserTargetWithTimer(KillTarget, FireTime);
	}
}