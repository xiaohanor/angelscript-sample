event void FOnHeadWeakpointFirstStrike();
event void FOnHeadWeakpointSecondStrike();
event void FOnHeadWeakpointDefeated();

class AStoneBeastHeadWeakpointManager : AHazeActor
{
	UPROPERTY()
	FOnHeadWeakpointFirstStrike OnHeadWeakpointFirstStrike;

	UPROPERTY()
	FOnHeadWeakpointSecondStrike OnHeadWeakpointSecondStrike;

	UPROPERTY()
	FOnHeadWeakpointDefeated OnHeadWeakpointDefeated;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"HeadWeakpointLightningStrikesCapability");

	UPROPERTY(EditAnywhere)
	AFocusCameraActor FocusCameraGauntlet;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor FocusCameraAngleLeftSide;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor FocusCameraAngleRightSide;

	UPROPERTY(EditAnywhere)
	APlayerTrigger PlayerTrigger;

	UPROPERTY(EditAnywhere)
	AStoneBossQTEWeakpoint Weakpoint;

	UPROPERTY(EditAnywhere)
	TArray<AStoneBeastHeadLightningPoint> LightingPoints;

	bool bRunThrowback;

	int Strikes = 0;

	bool bLightningAttack;

	bool bAttacksStageOne;
	bool bAttacksStageTwo;
	bool bAttacksStageThree;

	bool bInSafeZone;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Weakpoint.OnStoneBossWeakpointSuccessfulHit.AddUFunction(this, n"OnStoneBossWeakpointSuccessfulHit");
		// 	PlayerTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION(CallInEditor)
	void GetLightningPoints()
	{
		LightingPoints = TListedActors<AStoneBeastHeadLightningPoint>().GetArray();
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if (!bInSafeZone)
		{
			bInSafeZone = true;

			if (bAttacksStageOne)	
				Game::Zoe.ActivateCamera(FocusCameraAngleRightSide, 3, this, EHazeCameraPriority::High);
			else if (bAttacksStageTwo)
				Game::Zoe.ActivateCamera(FocusCameraAngleLeftSide, 3, this, EHazeCameraPriority::High);
		}
	}

	UFUNCTION()
	void StartGauntlet(int Stage = 1)
	{
		bInSafeZone = false;

		switch (Stage)
		{
			case 1:
				bAttacksStageOne = true;
				bLightningAttack = true;
				break;
			case 2:
				bAttacksStageTwo = true;
				bLightningAttack = true;
				break;
			case 3:
				bAttacksStageThree = true;
				break;
		}
	}

	//Broadcasts are read from level blueprint
	UFUNCTION()
	private void OnStoneBossWeakpointSuccessfulHit()
	{
		Strikes++;

		bLightningAttack = false;
		bAttacksStageOne = false;
		bAttacksStageTwo = false;
		bAttacksStageThree = false;

		Weakpoint.ForceEjectPlayers();

		switch (Strikes)
		{
			case 1:
				OnHeadWeakpointFirstStrike.Broadcast();
				break;
			case 2:
				OnHeadWeakpointSecondStrike.Broadcast();
				break;
			case 3:
				OnHeadWeakpointDefeated.Broadcast();
				break;
		}
	}
};