struct FPrisonBossCloneAttackParameters
{
	FRandomStream RandomStream;
}

class UPrisonBossCloneAttackCapability : UPrisonBossChildCapability
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	UPrisonBossCloneManagerComponent CloneComp;

	bool bReachedEnd = false;
	FVector TargetLocation;

	bool bSpawningClones = true;
	int ClonesAttacked = 0;

	float CurrentCloneAttackTime = 0.0;

	bool bTelegraphingFinalAttack = false;
	float CurrentTelegraphDuration = 0.0;

	bool bPerformingFinalAttack = false;

	float CurrentFinalAttackWindUp = 0.0;

	float CurrentAttackDuration = 0.0;

	FRandomStream RandomStream;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		CloneComp = UPrisonBossCloneManagerComponent::GetOrCreate(Boss);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FPrisonBossCloneAttackParameters& Parameters) const
	{
		Parameters.RandomStream = FRandomStream(Math::Rand());
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (CurrentAttackDuration >= PrisonBoss::CloneAttackDuration && bReachedEnd)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FPrisonBossCloneAttackParameters Parameters)
	{
		RandomStream = Parameters.RandomStream;

		CurrentCloneAttackTime = 0.0;
		ClonesAttacked = 0;
		bTelegraphingFinalAttack = false;
		CurrentTelegraphDuration = 0.0;
		bSpawningClones = true;
		CurrentFinalAttackWindUp = 0.0;

		bReachedEnd = false;

		TargetLocation = Boss.ActorLocation + (Boss.ActorForwardVector * 4500.0);

		UPrisonBossEffectEventHandler::Trigger_CloneStartAttacks(Boss);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Boss.AnimationData.bIsAttackingClone = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bSpawningClones)
		{
			CurrentCloneAttackTime += DeltaTime;
			if (CurrentCloneAttackTime >= PrisonBoss::CloneAttackInterval)
			{
				TriggerCloneAttack();
			}
		}
		else
		{
			if (bTelegraphingFinalAttack)
			{
				CurrentTelegraphDuration += DeltaTime;
				if (CurrentTelegraphDuration >= PrisonBoss::CloneTelegraphDuration)
					TriggerFinalAttack();
			}
			else
			{
				CurrentAttackDuration += DeltaTime;
				if (CurrentFinalAttackWindUp <= PrisonBoss::CloneAttackWindUp)
				{
					CurrentFinalAttackWindUp += DeltaTime;
					return;
				}

				FVector Loc = Math::VInterpConstantTo(Boss.ActorLocation, TargetLocation, DeltaTime, PrisonBoss::CloneAttackSpeed);
				Boss.SetActorLocation(Loc);

				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
				Trace.UseBoxShape(FVector(300.0, 300.0, 400.0), Boss.ActorQuat);

				FOverlapResultArray OverlapResults = Trace.QueryOverlaps(Boss.Mesh.GetSocketLocation(n"Hips"));

				for (FOverlapResult Overlap : OverlapResults)
				{
					AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
					if (Player != nullptr)
						Player.DamagePlayerHealth(1.0, FPlayerDeathDamageParams(Boss.ActorForwardVector, 3.0), Boss.ElectricityImpactDamageEffect, Boss.ElectricityImpactDeathEffect);
				}

				if (Loc.Equals(TargetLocation))
				{
					bReachedEnd = true;
					UPrisonBossEffectEventHandler::Trigger_CloneFinalAttackReachedEnd(Boss);
				}
			}
		}
	}

	void TriggerCloneAttack()
	{
		CurrentCloneAttackTime = 0.0;
		CloneComp.TriggerCloneAttack(RandomStream);
		ClonesAttacked++;

		if (ClonesAttacked >= PrisonBoss::MaxCloneAmount - 1)
		{
			StartTelegraphingFinalAttack();
			bSpawningClones = false;
		}
	}
	
	void StartTelegraphingFinalAttack()
	{
		bTelegraphingFinalAttack = true;
		Boss.AnimationData.bIsTelegraphingClone = true;

		UPrisonBossEffectEventHandler::Trigger_CloneFinalAttackTelegraph(Boss);
	}

	void TriggerFinalAttack()
	{
		bTelegraphingFinalAttack = false;
		Boss.AnimationData.bIsTelegraphingClone = false;
		Boss.AnimationData.bIsAttackingClone = true;

		Boss.BP_FinalCloneAttack();

		UPrisonBossEffectEventHandler::Trigger_CloneFinalAttackStarted(Boss);
	}
}

struct FPrisonBossCloneAttackEventData
{
	UPROPERTY()
	APrisonBossClone Clone = nullptr;

	FPrisonBossCloneAttackEventData(APrisonBossClone InClone)
	{
		Clone = InClone;
	}
}