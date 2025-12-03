class ASolarFlareMultiBridgeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(5.0));
#endif

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlareMultiBridge> Bridges;

	UPROPERTY(EditAnywhere)
	ASolarFlarePerchBattery PerchBattery;

	UPROPERTY(EditAnywhere)
	TArray<ASolarFlarePerchBattery> Batteries;

	UPROPERTY(EditAnywhere)
	AStaticCameraActor StaticCamera;

	// UPROPERTY(EditAnywhere)
	// ASplineActor 

	int CurrendIndex;
	int IndexesPerBattery;

	float ActivateRate = 0.1;
	float NextActivateTime;

	bool bGoingForwards = false;
	bool bCurrentGoingForwards;

	TPerPlayer<bool> bPlayerActiveOnPerch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		IndexesPerBattery = Math::IntegerDivisionTrunc(Bridges.Num(), Batteries.Num());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player.IsAnyCapabilityActive(PlayerMovementTags::Perch))
			{
				bool bPlayerUsingOurPerches = false;

				for (ASolarFlarePerchBattery Battery : Batteries)
				{
					if (Battery.BatteryActivated())
					{
						bPlayerUsingOurPerches = Battery.ActivePlayer == Player;
					}					
				}

				if (!bPlayerActiveOnPerch[Player] && bPlayerUsingOurPerches)
				{
					bPlayerActiveOnPerch[Player] = true;
					Player.ActivateCamera(StaticCamera, 2.5, this);
					FVector ConstrainedForward = StaticCamera.ActorForwardVector.ConstrainToPlane(FVector::UpVector);
					FVector ConstrainedRight = StaticCamera.ActorRightVector.ConstrainToPlane(FVector::UpVector);
					Player.LockInputToPlane(this, ConstrainedForward, ConstrainedRight);
				}
				//Player shouldn't be able to access any other perches, so only run this if not running perch behaviours
				else if (bPlayerActiveOnPerch[Player] && !bPlayerUsingOurPerches && !Player.IsAnyCapabilityActive(PlayerMovementTags::Perch))
				{
					bPlayerActiveOnPerch[Player] = false;
					Player.DeactivateCamera(StaticCamera, 2.5);
					Player.ClearLockInputToPlane(this);
				}
			}
		}

		for (int i = 0; i < Batteries.Num(); i++)
		{
			int StartIndex = i * IndexesPerBattery;
			if (StartIndex > 0)
				StartIndex--;
			int EndIndex = StartIndex + IndexesPerBattery;

			if (Batteries[i].BatteryActivated())
			{
				// PrintToScreen("StartIndex: " + StartIndex);
				// PrintToScreen("EndIndex: " + EndIndex);

				for (int b = 0; b < Bridges.Num(); b++)
				{
					if (b >= StartIndex && b <= EndIndex)
					{
						Bridges[b].ActivateMultiBridge();
					}
				}
			}
			else
			{
				for (int b = 0; b < Bridges.Num(); b++)
				{
					if (b >= StartIndex && b <= EndIndex)
					{
						Bridges[b].DeactivateMultiBridge();
					}
				}
			}
		}

		// if (Time::GameTimeSeconds > NextActivateTime)
		// {
		// 	NextActivateTime = Time::GameTimeSeconds + ActivateRate;
		// 	IterateIndex();
		// }
	}

	// void IterateIndex()
	// {
	// 	if (bCurrentGoingForwards != PerchBattery.BatteryActivated())
	// 	{
	// 		if (PerchBattery.BatteryActivated())
	// 			Bridges[CurrendIndex].ActivateMultiBridge();
	// 		else
	// 			Bridges[CurrendIndex].DeactivateMultiBridge();
	// 	}

	// 	CurrendIndex += PerchBattery.BatteryActivated() ? 1 : -1;
	// 	CurrendIndex = Math::Clamp(CurrendIndex, 0, Bridges.Num() - 1);

	// 	if (PerchBattery.BatteryActivated())
	// 		Bridges[CurrendIndex].ActivateMultiBridge();
	// 	else
	// 		Bridges[CurrendIndex].DeactivateMultiBridge();

	// 	bCurrentGoingForwards = PerchBattery.BatteryActivated();
	// }
}