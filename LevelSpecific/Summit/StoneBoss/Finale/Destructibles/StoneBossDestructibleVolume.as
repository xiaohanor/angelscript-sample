enum EStoneBossDestructibleVolumeType
{
	OnPlayerEnter,
	OnBothInside,
	OnBothHaveEntered,
	ManualActivation
}

class AStoneBossDestructibleVolume : APlayerTrigger
{
	default BrushComponent.LineThickness = 10.0;

	UPROPERTY(EditAnywhere)
	TArray<AStoneBossDestructiblePlatform> DestructiblePlatforms;

	UPROPERTY(EditAnywhere)
	EStoneBossDestructibleVolumeType Type;

	bool bRunDestruction;

	UPROPERTY(EditAnywhere)
	float DestructionRate = 1.0;
	float CurrentDestructionTime;

	int Count;

	TPerPlayer<bool> bHaveEntered;
	TPerPlayer<bool> bWithinVolume;

	bool bManualActivationStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		CurrentDestructionTime = DestructionRate;
		OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRunDestruction)
		{
			CurrentDestructionTime -= DeltaSeconds;

			if (CurrentDestructionTime <= 0.0)
			{
				CurrentDestructionTime = DestructionRate;
				DestructiblePlatforms[Count].ActivateDestructiblePlatform();
				Count++;

				if (Count > DestructiblePlatforms.Num() - 1)
				{
					SetActorTickEnabled(false);
				}
			}
		}
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		bHaveEntered[Player] = true;
		bWithinVolume[Player] = true;

		if (bRunDestruction)
			return;
		
		if (HasControl())
			CrumbCheckActivation(Player);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		bWithinVolume[Player] = false;
	}

	UFUNCTION()
	void ManualActivation()
	{	
		if (HasControl())
			CrumbManualActivation();
	}

	UFUNCTION(CrumbFunction)
	void CrumbManualActivation()
	{
		bManualActivationStarted = true;
		CrumbCheckActivation(nullptr);
	}

	UFUNCTION(CrumbFunction)
	void CrumbCheckActivation(AHazePlayerCharacter EnteredPlayer)
	{
		switch(Type)
		{
			case EStoneBossDestructibleVolumeType::OnBothHaveEntered:
				if (bHaveEntered[EnteredPlayer] && bHaveEntered[EnteredPlayer.OtherPlayer])
					bRunDestruction = true;
				break;
			case EStoneBossDestructibleVolumeType::OnBothInside:
				if (bWithinVolume[EnteredPlayer] && bWithinVolume[EnteredPlayer.OtherPlayer])
					bRunDestruction = true;
				break;
			case EStoneBossDestructibleVolumeType::OnPlayerEnter:
				bRunDestruction = true;
				break;
			case EStoneBossDestructibleVolumeType::ManualActivation:
				if (bManualActivationStarted)
					bRunDestruction = true;
				break;
		}
	}
}