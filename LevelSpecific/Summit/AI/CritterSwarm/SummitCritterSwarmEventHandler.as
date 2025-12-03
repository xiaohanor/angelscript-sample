UCLASS(Abstract)
class USummitCritterSwarmEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTelegraphAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttack(FCritterSwarmAttackEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackStop(){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnAttackHit(FCritterSwarmAttackHitEventParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnMeltCritter(FCritterSwarmMeltCritterEventParams Params){}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisperseCritterDeath(FCritterSwarmDisperseCritterEventParams Params){}

	float TelegraphZapTime = 0;

	UFUNCTION()
	void UpdateAttack(UNiagaraComponent EffectComp, FCritterSwarmAttackEventParams Params)
	{
		if (EffectComp == nullptr)
			return;

		FVector ZapStart = Params.AttackingCritter.WorldLocation;
		FVector ZapEnd = Params.TargetLoc + (Params.TargetLoc - ZapStart).GetSafeNormal() * Params.LengthPastTargetLoc;
		EffectComp.SetVectorParameter(n"Start", ZapStart);
		EffectComp.SetVectorParameter(n"End", ZapEnd);
	}

	UFUNCTION()
	void UpdateTelegraph(bool bTelegraph, UNiagaraSystem Effect)
	{
		if (!bTelegraph)
			return;

		if (Time::GameTimeSeconds < TelegraphZapTime)
			return;

		USummitCritterSwarmComponent SwarmComp = USummitCritterSwarmComponent::Get(Owner);
		if (SwarmComp.Critters.Num() == 0)
			return;

		TelegraphZapTime = Time::GameTimeSeconds + Math::RandRange(0.01, 0.1);	

		// Show zaps between various critters in swarm
		int iFrom = Math::RandRange(0, SwarmComp.Critters.Num() - 1);
		int iTo = Math::RandRange(0, SwarmComp.Critters.Num() - 1);

		// Attaching to a critter gives weird results (scaling maybe?)
		//UNiagaraComponent EffectComp = Niagara::SpawnOneShotNiagaraSystemAttached(Effect, SwarmComp.Critters[iFrom]);
		UNiagaraComponent EffectComp = Niagara::SpawnOneShotNiagaraSystemAttached(Effect, Owner.RootComponent); 
		EffectComp.SetVectorParameter(n"Start", SwarmComp.Critters[iFrom].WorldLocation);
		EffectComp.SetVectorParameter(n"End", SwarmComp.Critters[iTo].WorldLocation);
	}
}

struct FCritterSwarmAttackEventParams
{
	UPROPERTY()
	USummitSwarmingCritterComponent AttackingCritter;

	UPROPERTY()
	FVector TargetLoc;

	UPROPERTY()
	float LengthPastTargetLoc;

	FCritterSwarmAttackEventParams(USummitSwarmingCritterComponent AttackOrigin, FVector TargetLocation, float ExtraLength)
	{
		AttackingCritter = AttackOrigin;
		TargetLoc = TargetLocation;
		LengthPastTargetLoc = ExtraLength;
	}
}

struct FCritterSwarmMeltCritterEventParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase MeltingCritter;

	FCritterSwarmMeltCritterEventParams(UHazeSkeletalMeshComponentBase CritterToMelt)
	{
		MeltingCritter = CritterToMelt;
	}
}

struct FCritterSwarmDisperseCritterEventParams
{
	UPROPERTY()
	UHazeSkeletalMeshComponentBase Critter;

	FCritterSwarmDisperseCritterEventParams(UHazeSkeletalMeshComponentBase CritterToDisperse)
	{
		Critter = CritterToDisperse;
	}
}

struct FCritterSwarmAttackHitEventParams
{
	UPROPERTY()
	AAdultDragon HitDragon;

	FCritterSwarmAttackHitEventParams(AHazeActor Target)
	{
		UPlayerAdultDragonComponent DragonRiderComp = UPlayerAdultDragonComponent::Get(Target);
		// HitDragon = DragonRiderComp.AdultDragon;
	}
}

