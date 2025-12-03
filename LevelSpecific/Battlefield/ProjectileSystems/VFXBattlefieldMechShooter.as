class AVFXBattlefieldMechShooter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(10.0));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent EffectComp;
	default EffectComp.SetAutoActivate(false);

	float FireRate;
	float FireTime;
	float WaitDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}
};