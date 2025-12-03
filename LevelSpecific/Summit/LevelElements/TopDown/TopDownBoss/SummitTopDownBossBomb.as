class ASummitTopDownBossBomb : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MuralRoot;

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;
    
	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");

		// SetActorTickEnabled(false);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	void Activate()
	{
		Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
		Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);
	}
	

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		Activate();
		BP_Activate();
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Param)
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {
		
    }

}