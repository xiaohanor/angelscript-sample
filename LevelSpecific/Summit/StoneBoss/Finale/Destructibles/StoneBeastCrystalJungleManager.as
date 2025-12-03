event void FOnCrystalJungleAreaDestroyed();

class AStoneBeastCrystalJungleManager : AHazeActor
{
	UPROPERTY()
	FOnCrystalJungleAreaDestroyed OnCrystalJungleAreaDestroyed;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
	default Visual.SpriteName = "Scenepoint";
#endif

	UPROPERTY(EditAnywhere)
	TArray<AStoneBeastCrystalJungle> TriggerCrystals;

	TArray<AStoneBeastCrystalJungle> Crystals;

	UPROPERTY(EditAnywhere)
	bool bStartDisabled = false;

	
	int CrystalsDestroyed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AStoneBeastCrystalJungle Crystal : TriggerCrystals)
		{
			Crystal.OnCrystalJungleDestroyed.AddUFunction(this, n"OnCrystalJungleDestroyed");
		}
	}

	UFUNCTION()
	private void OnCrystalJungleDestroyed()
	{
		CrystalsDestroyed++;
		if (CrystalsDestroyed >= TriggerCrystals.Num() - 1)
		{
			OnCrystalJungleAreaDestroyed.Broadcast();
			AddActorDisable(this);
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		for (AStoneBeastCrystalJungle Crystal : Crystals)
		{
			Crystal.SetEndState();
		}	
	}

	UFUNCTION()
	void EnableCrystalJungle()
	{
		for (AStoneBeastCrystalJungle Crystal : Crystals)
		{
			Crystal.RemoveActorDisable(this);
		}	
	}

	UFUNCTION()
	void DisablePreviousCrystalJungle()
	{
		for (AStoneBeastCrystalJungle Crystal : Crystals)
		{
			Crystal.AddActorDisable(n"DisablePreviousCrystalJungle");
		}	
	}
};