event void FSkylineCombatManagerSignature(FString StageID);

struct FSkylineCombatManagerData
{
	bool bIsCompleted = false;
	bool bSpawnersDepleted = true;
	bool bActorsDead = true;

	UPROPERTY()
	FString StageID;

	UPROPERTY()
	TArray<AHazeActorSpawnerBase> Spawners;

	UPROPERTY()
	TArray<AHazeActor> Actors;
}

class ASkylineCombatManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent BillboardComp;
	default BillboardComp.WorldScale3D = FVector(3, 3, 3);

	UPROPERTY()
	FSkylineCombatManagerSignature OnStageComplete;

	UPROPERTY(EditAnywhere)
	TArray<FSkylineCombatManagerData> CombatStages;

	int EnemiesKilled = 0;

	UPROPERTY(EditAnywhere)
	TArray<AHazeActorSpawnerBase> TrackSpawners;

	TArray<ABasicAICharacter> TrackCharacters;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		/*
		for (int i = 0; i < TrackSpawners.Num(); i++)
		{
			TrackSpawners[i].ActivateSpawner();
			TrackSpawners[i].OnPostSpawn.AddUFunction(this, n"HandleSpawn");
		}
		*/

		for (auto& CombatStage : CombatStages)
		{
			for (auto Spawner : CombatStage.Spawners)
			{
				Spawner.OnDepleted.AddUFunction(this, n"HandleSpawnerDepleted");
				if (!Spawner.IsDepleted())
					CombatStage.bSpawnersDepleted = false;
			}

			for (auto Actor : CombatStage.Actors)
			{
				auto HealthComp = UBasicAIHealthComponent::Get(Actor);
				if (HealthComp != nullptr)
				{
					HealthComp.OnDie.AddUFunction(this, n"HandleActorDie");
					if (!HealthComp.IsDead())
						CombatStage.bActorsDead = false;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		PrintToScreen("Killed: " + EnemiesKilled, 0.0, FLinearColor::Green);
	}

	UFUNCTION()
	void PrepareCombatEvent()
	{
		for (auto TrackSpawner : TrackSpawners)
			TrackSpawner.OnPostSpawn.AddUFunction(this, n"HandleSpawn");

		ActivateNextSpawner();
/*
		for (int i = 0; i < TrackSpawners.Num(); i++)
		{
		//	TrackSpawners[i].ActivateSpawner();
			TrackSpawners[i].OnPostSpawn.AddUFunction(this, n"HandleSpawn");
		}		
*/
	}

	UFUNCTION()
	void StartCombatEvent()
	{
		for (int i = 0; i < 3; i++)
		{
			if (TrackCharacters.IsValidIndex(i))
				TrackCharacters[i].RemoveActorDisable(this);
			else
				break;
		}
	}

	void ActivateNextSpawner()
	{
		if (TrackSpawners.Num() == 0)
		{
			StartCombatEvent();
			return;
		}

		TrackSpawners[0].ActivateSpawner();
		TrackSpawners.RemoveAt(0);
	}

	UFUNCTION()
	private void HandleSpawn(AHazeActor SpawnedActor)
	{
		auto Character = Cast<ABasicAICharacter>(SpawnedActor);
		TrackCharacters.Add(Character);
		Character.AddActorDisable(this);
		Character.HealthComp.OnDie.AddUFunction(this, n"HandleDie");

		ActivateNextSpawner();
	}

	UFUNCTION()
	private void HandleDie(AHazeActor ActorBeingKilled)
	{
		EnemiesKilled++;

		for (int i = 0; i < TrackCharacters.Num(); i++)
		{
			if (!TrackCharacters[i].HealthComp.IsDead() && TrackCharacters[i].IsActorDisabled())
			{
				PrintToScreen("Enabled new enemy! " + TrackCharacters[i], 4.0, FLinearColor::Green);
				TrackCharacters[i].RemoveActorDisable(this);
				break;
			}
		}

//		if (EnemiesKilled == 3)
//			OnStageComplete.Broadcast("ProgressPoint");

		if (EnemiesKilled == TrackCharacters.Num())
			OnStageComplete.Broadcast("ElitesDead");
	}

	UFUNCTION()
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		auto HealthComp = UBasicAIHealthComponent::Get(ActorTakingDamage);
		if (HealthComp.CurrentHealth <= 0.0)
		{
			EnemiesKilled++;
		}
	}

	UFUNCTION()
	private void HandleSpawnerDepleted(AHazeActor LastActor)
	{
		for (auto& CombatStage : CombatStages)
		{
			if (CombatStage.bSpawnersDepleted)
				continue;

			int SpawnersDepleted = 0;

			for (auto Spawner : CombatStage.Spawners)
			{
				if (Spawner.IsDepleted())
					SpawnersDepleted++;
			}

			PrintToScreen("SkylineCombatManager: " + SpawnersDepleted + " / " + CombatStage.Spawners.Num() + " spawners in stage " + CombatStage.StageID + " depleted.", 5.0, FLinearColor::Green);

			if (SpawnersDepleted == CombatStage.Spawners.Num())
			{
				CombatStage.bSpawnersDepleted = true;
				UpdateCombatStage(CombatStage);
			}
		}	
	}

	UFUNCTION()
	private void HandleActorDie(AHazeActor ActorBeingKilled)
	{
		for (auto& CombatStage : CombatStages)
		{
			if (CombatStage.bActorsDead)
				continue;

			int ActorsDead = 0;

			for (auto Actor : CombatStage.Actors)
			{
				auto HealthComp = UBasicAIHealthComponent::Get(Actor);
				if (HealthComp != nullptr && HealthComp.IsDead())
					ActorsDead++;
			}

			PrintToScreen("SkylineCombatManager: " + ActorsDead + " / " + CombatStage.Actors.Num() + " actors in stage " + CombatStage.StageID + " dead.", 5.0, FLinearColor::Green);

			if (ActorsDead == CombatStage.Actors.Num())
			{
				CombatStage.bActorsDead = true;
				UpdateCombatStage(CombatStage);
			}
		}			
	}

	void UpdateCombatStage(FSkylineCombatManagerData& CombatStage)
	{
		if (CombatStage.bSpawnersDepleted && CombatStage.bActorsDead)
		{
			if (!CombatStage.bIsCompleted)
			{
				PrintToScreen("SkylineCombatManager: " + CombatStage.StageID + " complete!", 5.0, FLinearColor::Green);
				OnStageComplete.Broadcast(CombatStage.StageID);
			}

			CombatStage.bIsCompleted = true;
		}
	}

	UFUNCTION(BlueprintPure)
	bool IsCombatStageCompleted(FString StageID)
	{
		for (auto& CombatStage : CombatStages)
		{
			if (CombatStage.StageID == StageID && CombatStage.bIsCompleted)
				return true;
		}
	
		return false;
	}

	UFUNCTION()
	void ActivateCombatStage(FString StageID)
	{
		for (auto& CombatStage : CombatStages)
		{
			if (CombatStage.StageID == StageID && !CombatStage.bIsCompleted)
			{
				for (auto Spawner : CombatStage.Spawners)
					Spawner.ActivateSpawner();

				for (auto Actor : CombatStage.Actors)
					Actor.ClearAllDisables();
			}
		}
	}

	UFUNCTION()
	void DeactivateCombatStage(FString StageID)
	{
		for (auto& CombatStage : CombatStages)
		{
			if (CombatStage.StageID == StageID && !CombatStage.bIsCompleted)
			{
				for (auto Spawner : CombatStage.Spawners)
					Spawner.DeactivateSpawner();

				for (auto Actor : CombatStage.Actors)
					Actor.AddActorDisable(this);
			}
		}
	}
};