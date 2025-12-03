struct FSentryBossMortarSpawnPosition
{	
	int Collumn;
	int Row;
	FVector Location;
}


class ASkylineSentryBossMortarArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;
	default BillboardComp.SetRelativeScale3D(FVector(5));

	
	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossMortarAreaRowAttackCapability");
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ASkylineSentryBossMortar> Mortar;


	UPROPERTY()
	UNiagaraSystem FireNiagara;
	
	int Rows = 5;
	int Collumns = 5;
	float RowOffset = 500;
	float CollumnOffset = 300;


	TArray<ASkylineSentryBossMortar> MortarActors;
	TArray<FSentryBossMortarSpawnPosition> MortarSpawnPosition;

	float RowAttackCooldown;
	bool bReverseAttack;
	bool bRowAttack;
	bool bHasFireSpawned;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector StartLocation = ActorLocation - FVector((Collumns * RowOffset) / 2, (Rows * CollumnOffset) / 2, 0);
		StartLocation = ActorLocation + (ActorForwardVector * (Collumns * RowOffset) / 2) - (ActorRightVector * (Rows * CollumnOffset) / 2);
		FVector Location = StartLocation;
		

		for(int y = 0; y < Rows; y++)
		{
			Location = StartLocation + ActorRightVector * y * CollumnOffset;

			for(int x = 0; x < Collumns; x++)
			{
				Location -= ActorForwardVector * RowOffset;
				//Debug::DrawDebugPoint(Location, 50, FLinearColor::Red, 30, false);

				// FSentryBossMortarSpawnPosition NewMortarData;
				// NewMortarData.Row = y;
				// NewMortarData.Collumn = x;
				// NewMortarData.Location = Location;
				// MortarSpawnPosition.Add(NewMortarData);

				AActor SpawnedActor = SpawnActor(Mortar, Location, ActorRotation);
				ASkylineSentryBossMortar SpawnedMortar = Cast<ASkylineSentryBossMortar>(SpawnedActor);
				SpawnedMortar.Row = y;
				MortarActors.Add(SpawnedMortar);
			}
		}

	}


	void SpawnMortarAtPosition(int Collumn, int Row)
	{
		for(int i = 0; i < MortarSpawnPosition.Num(); i++)
		{
			if(MortarSpawnPosition[i].Collumn == Collumn && MortarSpawnPosition[i].Row == Row)
			{
				SpawnActor(Mortar, MortarSpawnPosition[i].Location, ActorRotation);
				return;
			}
		}

	}

	void RowAttack(bool IsAttackReversed, float AreaAttackInterval)
	{
		RowAttackCooldown = AreaAttackInterval / Rows;
		bRowAttack = true;
		bReverseAttack = IsAttackReversed;
	}

	void AllAttack()
	{	
		// for(int i = 0; i < MortarSpawnPosition.Num(); i++)
		// {
		// 	ShootMortarAtLocation(MortarSpawnPosition[i].Location);

		// 	// AActor SpawnedActor = SpawnActor(Mortar, MortarSpawnPosition[i].Location, ActorRotation);
		// 	// ASkylineSentryBossMortar SpawnedMortar = Cast<ASkylineSentryBossMortar>(SpawnedActor);
		// 	// SpawnedMortar.MortarArea = this;
		// }

		for(ASkylineSentryBossMortar MortarActor : MortarActors)
		{
			MortarActor.Activate();
		}
	}

	// void ShootMortarAtLocation(FVector Location)
	// {
	// 	AActor SpawnedActor = SpawnActor(Mortar, Location, ActorRotation);

	// }


	// void SpawnFire()
	// {
	// 	// if(bHasFireSpawned)
	// 	// 	return;

	// 	// bHasFireSpawned = true;
	// 	Niagara::SpawnLoopingNiagaraSystemAttached(FireNiagara, Root);
	// }

};