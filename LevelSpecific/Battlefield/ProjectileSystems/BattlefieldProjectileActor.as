class ABattlefieldProjectileActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Root)
	UBattlefieldProjectileComponent ProjComp;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(2.0));
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UFUNCTION()
	void ActivateAutoFire()
	{
		ProjComp.ActivateAutoFire(0.0);
	}

	UFUNCTION()
	void DeactivateAutoFire()
	{
		ProjComp.DeactivateAutoFire();
	}
}