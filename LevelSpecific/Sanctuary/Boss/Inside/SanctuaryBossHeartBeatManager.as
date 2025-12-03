event void SanctuaryHeartBeatDeactivatedSignature();
event void SanctuaryHeartBeatActivated(bool bSpawnAttack = false);
event void SanctuaryHeartAttackZoeSmokeSignature();

class ASanctuaryBossHeartBeatManager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossInsideElectricCable> CableArray;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossHeartClaf> ClafArray;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	TSubclassOf<ASanctuaryBossFinalPhaseBlackSmoke> SmokeClass;

	UPROPERTY()
	FRuntimeFloatCurve HeartBeatCurve;

	UPROPERTY()
	FRuntimeFloatCurve AttackHeartBeatCurve;

	TArray<AActor> AttachedActors;

	UPROPERTY()
	float HeartRate = 3.0;

	UPROPERTY()
	int SpawnedSmokeActors = 30;

	UPROPERTY()
	int HeartBeatsPerSmokeSpawn = 3;
	int CurrentHeartBeat = HeartBeatsPerSmokeSpawn - 1;

	UPROPERTY(EditAnywhere)
	float SmokeDamage = 0.5;

	UPROPERTY(EditInstanceOnly)
	AStaticMeshActor HeartMesh;

	UPROPERTY()
	SanctuaryHeartBeatDeactivatedSignature OnDeactivated;

	UPROPERTY()
	SanctuaryHeartBeatActivated OnHeartBeat;

	UPROPERTY()
	SanctuaryHeartAttackZoeSmokeSignature OnSmokeHeartAttackZoe;

	bool bSendElectricity = false;
	bool bSpawnSmoke = false;

	float HeartTime = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAttachedActors(AttachedActors,true, true);
	}

	UFUNCTION()
	void Activate()
	{
		CallSendPulse();
	}

	UFUNCTION()
	void Deactivate()
	{
		QueueComp.Empty();
		OnDeactivated.Broadcast();

		if (HeartMesh != nullptr)
		{
			HeartMesh.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BrainPulseTime", -1.0);
		}
	}

	UFUNCTION()
	void StartSendElectricity()
	{
		bSendElectricity = true;
	}

	UFUNCTION()
	void StopSendElectricity()
	{
		bSendElectricity = false;
	}

	UFUNCTION()
	void StartSpawnSmoke()
	{
		bSpawnSmoke = true;
	}

	UFUNCTION()
	void StopSpawnSmoke()
	{
		bSpawnSmoke = false;
		OnDeactivated.Broadcast();
	}

	UFUNCTION()
	void FakeSpecialPulse()
	{
		for (auto Claf : ClafArray)
		{
			Claf.CallHeartBeat();
		}
	}

	UFUNCTION()
	private void HeartMaterialUpdate(float Alpha, bool bSpawnAttack = false)
	{
		if (HeartMesh == nullptr)
			return;

		float CurrentValue = HeartBeatCurve.GetFloatValue(Alpha);
		float HeartProgress = PI + CurrentValue * PI + 0.3;

		HeartMesh.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BrainPulseTime", HeartProgress);
		
		if (bSpawnAttack)
			HeartMesh.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BrainPulseStrength", 400.0 + AttackHeartBeatCurve.GetFloatValue(Alpha) * 500.0);
		else
			HeartMesh.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"BrainPulseStrength", 400.0);
	}

	UFUNCTION()
	private void CallSendPulse()
	{
		bool bSpawnAttack = false;

		for (auto Claf : ClafArray)
		{
			Claf.CallHeartBeat();
		}

		if (bSendElectricity)
		{
			for (auto Cable : CableArray)
			{
				Cable.CallSendPulse();
			}

			bSpawnAttack = true;

			BP_SentPulse();
		}

		if (bSpawnSmoke)
		{		
			CurrentHeartBeat++;

			if (CurrentHeartBeat >= HeartBeatsPerSmokeSpawn)
			{
				for (auto AttachedActor : AttachedActors)
				{
					FRotator Rotation;
					Rotation = Math::GetRandomConeDirection(AttachedActor.ActorRotation.ForwardVector, 0.3).Rotation();

					auto Smoke = SpawnActor(
						SmokeClass, 
						AttachedActor.ActorLocation, 
						//AttachedActor.ActorRotation + 
						Rotation,
						bDeferredSpawn = true);

					Smoke.Damage = SmokeDamage;
					Smoke.HeartManager = this;
					OnDeactivated.AddUFunction(Smoke, n"HandleDeactivated");
					FinishSpawningActor(Smoke);
				}

				BP_SpawnedSmoke();
				
				CurrentHeartBeat -= HeartBeatsPerSmokeSpawn;
			}

			if (CurrentHeartBeat == HeartBeatsPerSmokeSpawn - 1)
				bSpawnAttack = true;
			
			// for (int i = 0; i < SpawnedSmokeActors; i++)
			// {
			// 	SpawnActor(
			// 		SmokeClass, 
			// 		ActorLocation, 
			// 		FRotator(
			// 				Math::RandRange(-30.0, 30.0), 
			// 				Math::RandRange(90.0, 270.0), 
			// 				0.0));
			// }
		}

		OnHeartBeat.Broadcast(bSpawnAttack);

		QueueComp.Duration(HeartRate, this, n"HeartMaterialUpdate", bSpawnAttack);
		QueueComp.Event(this, n"CallSendPulse");
	}

	UFUNCTION(BlueprintEvent)
	private void BP_SpawnedSmoke(){}

	UFUNCTION(BlueprintEvent)
	private void BP_SentPulse(){}
};