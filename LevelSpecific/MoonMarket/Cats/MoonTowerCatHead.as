class AMoonTowerCatHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BigCatMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ActivateEffect;
	default ActivateEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FX_Loop;
	default FX_Loop.SetAutoActivate(false);

	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	AMoonGateCatHead GateCatHead; 

	UPROPERTY(EditAnywhere)
	float GateDelayTime = 3.0;

	UPROPERTY(EditAnywhere)
	bool bAutoActivateGate = true;

	UFUNCTION()
	void CatHeadActivated()
	{
		BigCatMesh.SetMaterial(0, Material);
		ActivateEffect.Activate();
		FX_Loop.Activate();

		if (bAutoActivateGate)
			Timer::SetTimer(this, n"DelayedGateCatActivate", GateDelayTime);
	}

	UFUNCTION(NotBlueprintCallable)
	void DelayedGateCatActivate()
	{
		GateCatHead.CatHeadActivated(Material);
	}

	UFUNCTION()
	void ManualGateCatActivate()
	{
		GateCatHead.CatHeadActivated(Material);
	}
};