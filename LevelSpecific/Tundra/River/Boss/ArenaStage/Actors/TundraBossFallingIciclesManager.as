class ATundraBossFallingIciclesManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundraBossFallingIcicle> FallingIcicles;

	UPROPERTY(EditInstanceOnly)
	AHazeActor IcicleZLocationPhase02;
	UPROPERTY(EditInstanceOnly)
	AHazeActor IcicleZLocationPhase03;

	UPROPERTY(EditInstanceOnly)
	TArray<FTundraBossFallingIcicleFallSequenceData> FallSequenceData;

	int CurrentFallSequenceIndex = 0;

	int CurrentIcicleIndex = 0;

	float CurrentZValue = 0;
	float IcicleTimer = 0;
	float IcicleTimerDuration = 0;
	bool bShouldTickIcicleTimer = false;
	bool bIciclesActive = false;

	ATundraBossAttackRestrictionZone CurrentRestrictedZone;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bShouldTickIcicleTimer)
			return;

		IcicleTimer += DeltaSeconds;
		if(IcicleTimer >= IcicleTimerDuration)
		{
			IcicleTimer = 0;
			if(!bIciclesActive)
				bShouldTickIcicleTimer = false;
			else
				DropIcicles();
		}
	}

	void StartDroppingIcicles(float NewDropInterval, bool IsLastPhase)
	{
		IcicleTimerDuration = NewDropInterval;

		if(IsLastPhase)
			CurrentZValue = IcicleZLocationPhase03.ActorLocation.Z;
		else
			CurrentZValue = IcicleZLocationPhase02.ActorLocation.Z;

		if(!bIciclesActive)
		{
			DropIcicles();
			IcicleTimer = 0;
			bShouldTickIcicleTimer = true;
			bIciclesActive = true;
		}
	}

	void StopDroppingIcicles()
	{
		bIciclesActive = false;
	}

	UFUNCTION()
	void DropIcicles()
	{
		for(auto Player : Game::GetPlayers())
			DropIcicleOnPlayer(Player);
	}

	void DropIcicleOnPlayer(AHazePlayerCharacter Player)
	{
		if(Player.IsPlayerDead())
			return;

		if(Player.IsAnyCapabilityActive(n"TundraPlayerTreeGuardianRangedShootCapability"))
			return;

		if(CurrentIcicleIndex >= FallingIcicles.Num() - 5)
			CurrentIcicleIndex = 0;

		float Delay = 0;
		FVector PlayerPredictedLocation = Player.ActorLocation + Player.ActorHorizontalVelocity * 1.5;
		int LocalIndex = 0;

		bool bInRestrictedZone = false;
		if(CurrentRestrictedZone != nullptr)
			bInRestrictedZone = CurrentRestrictedZone.PlayerCurrentlyInRestrictedZone(Player, 200);
		
		if(!bInRestrictedZone)
		{
			for(int i = CurrentIcicleIndex; i < CurrentIcicleIndex + FallSequenceData[CurrentFallSequenceIndex].NumberOfIcicles; i++)
			{				
				if(LocalIndex == 0)
					FallingIcicles[i].StartIcicleDrop(Player.ActorLocation, CurrentZValue, Delay);
				else
				{
					FallingIcicles[i].StartIcicleDrop(PlayerPredictedLocation + GetRandomOffset(LocalIndex, Player), CurrentZValue, Delay);
				}
				Delay += FallSequenceData[CurrentFallSequenceIndex].DropDelay[LocalIndex];
				LocalIndex++;
			}
		}
		else
		{
			for(int i = CurrentIcicleIndex; i < CurrentIcicleIndex + FallSequenceData[CurrentFallSequenceIndex].NumberOfIcicles; i++)
			{				
				FallingIcicles[i].StartIcicleDrop(CurrentRestrictedZone.GetSpawnLocationWithRestriction(Player, 200), CurrentZValue, Delay);
				Delay += FallSequenceData[CurrentFallSequenceIndex].DropDelay[LocalIndex];
				LocalIndex++;
			}
		}

		CurrentIcicleIndex += LocalIndex;

		CurrentFallSequenceIndex++;
		
		if(CurrentFallSequenceIndex >= FallSequenceData.Num())
			CurrentFallSequenceIndex = 0;
	}

	// TODO: Will get different offsets in network...
	FVector GetRandomOffset(int LocalIndex, AHazePlayerCharacter Player)
	{
		if(LocalIndex <= 1)
			return FVector::ZeroVector;

		FVector Offset;
		FVector OffsetDir = Player.ActorVelocity.GetSafeNormal().CrossProduct(FVector::UpVector);
		
		int OffsetMultiplier = 0;
		if(LocalIndex == 2)
			OffsetMultiplier = 1;
		else if(LocalIndex == 3)
			OffsetMultiplier = -1;

		FVector Dir = Player.ActorVelocity.GetSafeNormal();
		if(Dir.IsNearlyZero())
		{
			float RandomAngle = Math::RandRange(0.0, 360.0);
			Dir = Math::RotatorFromAxisAndAngle(FVector::UpVector, RandomAngle).ForwardVector;
		}
		Dir *= Math::RandRange(75 * OffsetMultiplier, 150 * OffsetMultiplier);
		Offset += OffsetDir * Math::RandRange(250 * OffsetMultiplier, 450 * OffsetMultiplier);
		Offset += Dir;
		
		return Offset;
	}

	UFUNCTION()
	void SetNewFallingIcicleRestrictionZone(ATundraBossAttackRestrictionZone NewZone)
	{
		CurrentRestrictedZone = NewZone;
	}

	UFUNCTION()
	void ClearFallingIcicleRestrictionZone()
	{
		CurrentRestrictedZone = nullptr;
	}

	UFUNCTION(CallInEditor)
	void CreateFallSequenceData()
	{
		FallSequenceData.Empty();
	
		for(int i = 0; i < 40; i++)
		{
			FTundraBossFallingIcicleFallSequenceData Data;
			Data.NumberOfIcicles = Math::RandRange(1, 5);

			for(int j = 0; j < Data.NumberOfIcicles; j++)
			{
				Data.DropDelay.Add(Math::RandRange(0.05, 0.2));
			}

			FallSequenceData.Add(Data);
		}
	}
};

struct FTundraBossFallingIcicleFallSequenceData
{
	UPROPERTY()
	int NumberOfIcicles;
	UPROPERTY()
	TArray<float> DropDelay;
}