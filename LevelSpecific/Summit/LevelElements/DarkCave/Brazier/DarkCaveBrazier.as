class ADarkCaveBrazier : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent Brazier;
	default Brazier.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	USummitDarkCaveSaveComponent SaveComp;


	UPROPERTY(EditAnywhere)
	ADarkCaveSpiritStatue Statue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Statue.OnSummitGemDestroyed.AddUFunction(this, n"OnSummitGemDestroyed");
		SaveComp.OnSummitDarkCaveActivateSave.AddUFunction(this, n"OnSummitDarkCaveActivateSave");
	}

	UFUNCTION()
	private void OnSummitGemDestroyed(ASummitNightQueenGem CrystalDestroyed)
	{
		ActivateBrazier();
	}

	UFUNCTION()
	private void OnSummitDarkCaveActivateSave()
	{
		ActivateBrazier();
	}

	void ActivateBrazier()
	{
		Brazier.Activate();
		UDarkCaveBrazierEventHandler::Trigger_OnFireStarted(this);
	}
};