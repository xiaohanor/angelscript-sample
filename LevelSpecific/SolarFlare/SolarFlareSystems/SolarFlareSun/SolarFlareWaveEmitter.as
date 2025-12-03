class ASolarFlareWaveEmitter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FXComp;
	//GameplayLargeLaserCannon_01
	default FXComp.bAutoActivate = false;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(50.0));
#endif

	void ActivateWaveEmitter()
	{
		FXComp.Activate();
	}

	void DeactivateWaveEmitter()
	{
		FXComp.Deactivate();
	}
}