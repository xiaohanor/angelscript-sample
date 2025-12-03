class ATundraBossSetupIceFloorNew : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Floor0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Floor1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Floor2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Floor3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Floor4;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeLevelSequenceActor> SimulationLevelSequences;

	TArray<UStaticMeshComponent> FloorMeshes;
	TArray<int> IntactFlorMeshesIndexes;
	UStaticMeshComponent MeshToRemoveCollisionOn;

	UPROPERTY(EditInstanceOnly)
	ATundraBossSetup Boss;

	UPROPERTY()
	UMaterialInterface OverlayMat;

	int MioPlatformIndex = -1;
	int ZoePlatformIndex = -1;
	int CurrentFloorIndex = -1;

	TArray<ATundraBossSetupSmashAttackActor> SmashAttackActors;
	TArray<ATundraBossSetupDestroyIceAttackActor> DestroyIceAttackActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FloorMeshes.Add(Floor0);
		FloorMeshes.Add(Floor1);
		FloorMeshes.Add(Floor2);
		FloorMeshes.Add(Floor3);
		FloorMeshes.Add(Floor4);

		for(int i = 0; i < FloorMeshes.Num(); i++)
		{
			if(i == 0)
				continue;

			IntactFlorMeshesIndexes.Add(i);
		}

		Boss.OnTundraBossSetupBrokeIceFromUnderIce.AddUFunction(this, n"OnTundraBossSetupBrokeIceFromUnderIce");
		Boss.OnTundraBossBrokeFloor.AddUFunction(this, n"OnTundraBossBrokeFloor");

		SmashAttackActors = TListedActors<ATundraBossSetupSmashAttackActor>().GetArray();
		DestroyIceAttackActors = TListedActors<ATundraBossSetupDestroyIceAttackActor>().GetArray();
	}

	int GetPlayersPlatformIndex(AHazePlayerCharacter PreferedTargetPlayer, bool bFirstIndexIsValidTarget, bool bDestroysPlatformAfterAttack)
	{
		for(auto Player : Game::GetPlayers())
		{
			FVector TraceStart = Player.ActorLocation;
			FVector TraceEnd = Player.ActorLocation - FVector(0, 0, 2000);
			auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			Trace.IgnorePlayers();
			auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

			int CurrentPlatformIndex = 0;
			
			if (HitResult.bBlockingHit)
			{
				auto MeshComp = Cast<UStaticMeshComponent>(HitResult.Component);
				if(MeshComp != nullptr)
				{
					CurrentPlatformIndex = FloorMeshes.FindIndex(MeshComp);
				}
				else
				{
					CurrentPlatformIndex = -1;
				}
			}
			else
			{
				CurrentPlatformIndex = -1;
			}

			// The prefered target player is on a valid platform index.
			if(Player == PreferedTargetPlayer && bIsValidIndex(CurrentPlatformIndex, bFirstIndexIsValidTarget))
			{
				if(bDestroysPlatformAfterAttack)
					IntactFlorMeshesIndexes.Remove(CurrentPlatformIndex);
				
				SetForeShadowOverlay(CurrentPlatformIndex);
				return CurrentPlatformIndex;
			}

			if(Player.IsMio())
				MioPlatformIndex = CurrentPlatformIndex;
			else
				ZoePlatformIndex = CurrentPlatformIndex;
		}

		TArray<int> PlayersPlatformIndex;
		PlayersPlatformIndex.Add(MioPlatformIndex);
		PlayersPlatformIndex.Add(ZoePlatformIndex);

		// Gets the index from the non prefered player if the index of the perefered player isn't valid.
		for(auto Index : PlayersPlatformIndex)
		{
			if(bIsValidIndex(Index, bFirstIndexIsValidTarget))
			{
				if(bDestroysPlatformAfterAttack)
					IntactFlorMeshesIndexes.Remove(Index);
				
				SetForeShadowOverlay(Index);
				return Index;
			}
		}

		// None of the player's indexes were valid, return a random from one of the remaining ones. 
		int RandomIndex = IntactFlorMeshesIndexes[Math::RandRange(0, IntactFlorMeshesIndexes.Num() - 1)];
		
		if(bDestroysPlatformAfterAttack)
			IntactFlorMeshesIndexes.Remove(RandomIndex);
		
		SetForeShadowOverlay(RandomIndex);
		return RandomIndex;
	}

	bool bIsValidIndex(int Index, bool bFirstIndexIsValidTarget)
	{
		if(!bFirstIndexIsValidTarget && Index == 0)
			return false;
		if(Index == -1)
			return false;

		return true;
	}

	void SetForeShadowOverlay(int Index)
	{
		if(HasControl())
			CrumbSetForeShadowOverlay(Index);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetForeShadowOverlay(int Index)
	{
		FloorMeshes[Index].SetOverlayMaterial(OverlayMat);
	}

	UFUNCTION()
	void RemoveForeshadowOverlay()
	{
		FloorMeshes[CurrentFloorIndex].SetOverlayMaterial(nullptr);
	}
	
	UFUNCTION()
	private void OnTundraBossSetupBrokeIceFromUnderIce(int FloorIndexToBreak)
	{
		CurrentFloorIndex = FloorIndexToBreak;
		auto Mesh = FloorMeshes[FloorIndexToBreak];
		MeshToRemoveCollisionOn = Mesh;
		Timer::SetTimer(this, n"RemoveCollision", GetCollisionRemovalDelay(FloorIndexToBreak));
		Timer::SetTimer(this, n"RemoveForeshadowOverlay", GetCollisionRemovalDelay(FloorIndexToBreak) * 0.8);
		SimulationLevelSequences[FloorIndexToBreak].PlayLevelSequenceSimple();
	}

	UFUNCTION()
	private void OnTundraBossBrokeFloor(int FloorIndexToBreak)
	{
		CurrentFloorIndex = FloorIndexToBreak;
		auto Mesh = FloorMeshes[FloorIndexToBreak];
		MeshToRemoveCollisionOn = Mesh;
		Timer::SetTimer(this, n"RemoveCollision", GetCollisionRemovalDelay(FloorIndexToBreak));
		Timer::SetTimer(this, n"RemoveForeshadowOverlay", GetCollisionRemovalDelay(FloorIndexToBreak) * 0.8);
		SimulationLevelSequences[FloorIndexToBreak].PlayLevelSequenceSimple();
	}

	UFUNCTION()
	void RemoveCollision()
	{
		MeshToRemoveCollisionOn.CollisionEnabled = ECollisionEnabled::NoCollision;
	}

	float GetCollisionRemovalDelay(int Index)
	{
		switch(Index)
		{
			case 0:
				return 0;
			case 1:
				return 0.3;
			case 2:
				return 0.5667;
			case 3:
				return 0.3;
			case 4:
				return 0.5;
			default:
				return 0;
		}
	}
};