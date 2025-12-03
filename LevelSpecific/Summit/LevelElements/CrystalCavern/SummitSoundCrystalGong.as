event void FOnCrystalGongKnocked();

class ASummitSoundCrystalGong: AHazeActor
{
	FOnCrystalGongKnocked OnCrystalGongKnocked;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MuralRoot;

	UPROPERTY(DefaultComponent, Attach = MuralRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailResponseComp;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

    UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitSoundCrystal> SummitSoundCrystals; 

	UPROPERTY(EditAnywhere, Category = "Setup")
	TArray<ASummitSoundCrystal> SummitSoundCrystalsToDestroy; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		TailResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");
	}

	UFUNCTION()
	void Activate()
	{
		OnCrystalGongKnocked.Broadcast();
		Game::Mio.PlayCameraShake(CameraShake, this, 1.0);
		Game::Zoe.PlayCameraShake(CameraShake, this, 1.0);

        for (auto CrystalPiece : SummitSoundCrystals)
		{
            CrystalPiece.Play();
		}

		for (auto CrystalPiece : SummitSoundCrystalsToDestroy)
		{
			if(CrystalPiece.bIsStopped)
	            CrystalPiece.CrackPlatform();
		}
	}
	

	UFUNCTION()
	private void OnHitByRoll(FRollParams Params)
	{
		Activate();
		BP_Activate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {
		
	}


}