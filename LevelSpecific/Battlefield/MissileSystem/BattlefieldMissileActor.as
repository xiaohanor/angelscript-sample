class ABattlefieldMissileActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UBattlefieldMissileComponent MissileComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(4.0));
#endif

	UFUNCTION()
	void ActivateMissile()
	{
		MissileComp.SpawnMissile();
	}
};