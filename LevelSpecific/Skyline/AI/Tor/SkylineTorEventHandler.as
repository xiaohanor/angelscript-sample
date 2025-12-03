UCLASS(Abstract)
class USkylineTorEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnTakeDamage() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHammerHitGeneral(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackTelegraphStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackTelegraphStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwingAttackImpact(FSkylineTorEventHandlerOnSwingAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisarmStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDisarmStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRainDebrisTelegraphStart(FSkylineTorEventHandlerOnRainDebrisTelegraphStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRainDebrisTelegraphStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnBladeHit(FSkylineTorEventHandlerOnBladeHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
    void OnInterrupt(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExposedStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnExposedStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRearmStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRearmStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeployMineStart(FSkylineTorEventHandlerOnDeployMineStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDeployMineStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnControlMineStart(FSkylineTorEventHandlerOnControlMineStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnControlMineStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindTelegraphStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindTelegraphStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindAttackStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindAttackStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindAttackHit(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhirlwindAttackSwing() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackTelegraphStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackTelegraphStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnChargeAttackHit(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackTelegraphStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackTelegraphStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackHit(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSmashAttackImpact(FSkylineTorEventHandlerOnSmashAttackImpactData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackTelegraphStart(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackTelegraphStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackDiveStart(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackDiveStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackDiveHit(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLandStart(FSkylineTorEventHandlerOnDiveAttackLandStartData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLandStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapStart(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapHit(FSkylineTorEventHandlerHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapInterrupt(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapLandStart(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackLeapLandStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackRecoverStart(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDiveAttackRecoverStop(FSkylineTorEventHandlerDiveAttackData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStormAttackTelegraph(FSkylineTorEventHandlerOnStormAttackStartData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStormAttackStart(FSkylineTorEventHandlerOnStormAttackStartData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStormAttackStop(FSkylineTorEventHandlerGeneralData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnStormAttackHit(FSkylineTorEventHandlerOnStormAttackHitData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnOpportunityAttackImpact(FSkylineTorEventHandlerGeneralData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEjectAttackStart(FSkylineTorEventHandlerOnEjectAttackData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEjectAttackDamage(FSkylineTorEventHandlerOnEjectAttackData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEjectAttackEject(FSkylineTorEventHandlerOnEjectAttackData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEjectAttackStop(FSkylineTorEventHandlerOnEjectAttackData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnEjectAttackUpdate(FSkylineTorEventHandlerOnEjectAttackData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoldHammerVolleyThrow(FSkylineTorEventHandlerGeneralData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHoldHammerSpiralThrow(FSkylineTorEventHandlerGeneralData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPhaseChange(FSkylineTorEventHandlerPhaseChangeData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseAttackStartNewWave() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseAttackPrime() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseAttackFire() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPulseAttackImpact(FSkylineTorPulseImpactEventData Data) { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoloAttackStart() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoloAttackStop() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBoloAttackFire() { }

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecallHammerStart(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnRecallHammerStop(FSkylineTorEventHandlerGeneralData Data) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIdleStart() {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnIdleStop() {}
}

struct FSkylineTorEventHandlerPhaseChangeData
{
	UPROPERTY()
	ESkylineTorPhase NewPhase;
	UPROPERTY()
	ESkylineTorPhase OldPhase;
	UPROPERTY()
	ESkylineTorSubPhase NewSubPhase;
	UPROPERTY()
	ESkylineTorSubPhase OldSubPhase;

	FSkylineTorEventHandlerPhaseChangeData(ESkylineTorPhase _NewPhase, ESkylineTorPhase _OldPhase, ESkylineTorSubPhase _NewSubPhase, ESkylineTorSubPhase _OldSubPhase)
	{
		NewPhase = _NewPhase;
		OldPhase = _OldPhase;
		NewSubPhase = _NewSubPhase;
		OldSubPhase = _OldSubPhase;
	}
}

struct FSkylineTorPulseImpactEventData
{
	UPROPERTY()
	FVector ImpactLocation;

	FSkylineTorPulseImpactEventData(FVector _ImpactLocation)
	{
		ImpactLocation = _ImpactLocation;
	}
}

struct FSkylineTorEventHandlerGeneralData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;

	FSkylineTorEventHandlerGeneralData(ASkylineTorHammer InHammer)
	{
		Hammer = InHammer;
	}
}

struct FSkylineTorEventHandlerHitData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	FHitResult Hit;

	FSkylineTorEventHandlerHitData(ASkylineTorHammer InHammer, FHitResult _Hit)
	{
		Hammer = InHammer;
		Hit = _Hit;
	}
}

struct FSkylineTorEventHandlerOnEjectAttackData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	AHazeActor TargetActor;

	FSkylineTorEventHandlerOnEjectAttackData(ASkylineTorHammer InHammer, AHazeActor _TargetActor)
	{
		Hammer = InHammer;
		TargetActor = _TargetActor;
	}
}

struct FSkylineTorEventHandlerDiveAttackData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;

	UPROPERTY()
	USkylineTorDiveAttackComponent DiveAttackComp;

	FSkylineTorEventHandlerDiveAttackData(ASkylineTorHammer InHammer, USkylineTorDiveAttackComponent InDiveAttackComp)
	{
		Hammer = InHammer;
		DiveAttackComp = InDiveAttackComp;
	}
}

struct FSkylineTorEventHandlerOnDiveAttackLandStartData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	USkylineTorDiveAttackComponent DiveAttackComp;

	FSkylineTorEventHandlerOnDiveAttackLandStartData(ASkylineTorHammer InHammer, USkylineTorDiveAttackComponent InDiveAttackComp)
	{
		Hammer = InHammer;
		DiveAttackComp = InDiveAttackComp;
	}
}

struct FSkylineTorEventHandlerOnStormAttackStartData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	USkylineTorStormAttackComponent StormAttackComp;

	FSkylineTorEventHandlerOnStormAttackStartData(ASkylineTorHammer InHammer, USkylineTorStormAttackComponent InStormAttackComp)
	{
		Hammer = InHammer;
		StormAttackComp = InStormAttackComp;
	}
}

struct FSkylineTorEventHandlerOnStormAttackHitData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	USkylineTorStormAttackComponent StormAttackComp;
	UPROPERTY()
	AHazeActor HitActor;

	FSkylineTorEventHandlerOnStormAttackHitData(ASkylineTorHammer InHammer, USkylineTorStormAttackComponent InStormAttackComp, AHazeActor _HitActor)
	{
		Hammer = InHammer;
		StormAttackComp = InStormAttackComp;
		HitActor = _HitActor;
	}
}


struct FSkylineTorEventHandlerOnRainDebrisTelegraphStartData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	TArray<FVector> SpawnLocations;

	FSkylineTorEventHandlerOnRainDebrisTelegraphStartData(ASkylineTorHammer InHammer, TArray<FVector> InSpawnLocations)
	{
		Hammer = InHammer;
		SpawnLocations = InSpawnLocations;
	}
}

struct FSkylineTorEventHandlerOnSwingAttackImpactData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	FVector ImpactLocation;

	FSkylineTorEventHandlerOnSwingAttackImpactData(ASkylineTorHammer InHammer, FVector InImpactLocation)
	{
		Hammer = InHammer;
		ImpactLocation = InImpactLocation;
	}
}

struct FSkylineTorEventHandlerOnSmashAttackImpactData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	FVector ImpactLocation;

	FSkylineTorEventHandlerOnSmashAttackImpactData(ASkylineTorHammer InHammer, FVector InImpactLocation)
	{
		Hammer = InHammer;
		ImpactLocation = InImpactLocation;
	}
}


struct FSkylineTorEventHandlerOnDeployMineStartData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	ASkylineTorMine Mine;

	FSkylineTorEventHandlerOnDeployMineStartData(ASkylineTorHammer InHammer, ASkylineTorMine InMine)
	{
		Hammer = InHammer;
		Mine = InMine;
	}
}

struct FSkylineTorEventHandlerOnControlMineStartData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	ASkylineTorMine Mine;

	FSkylineTorEventHandlerOnControlMineStartData(ASkylineTorHammer InHammer, ASkylineTorMine InMine)
	{
		Hammer = InHammer;
		Mine = InMine;
	}
}

struct FSkylineTorEventHandlerOnBladeHitData
{
	UPROPERTY()
	ASkylineTorHammer Hammer;
	UPROPERTY()
	FGravityBladeHitData Hit;

	FSkylineTorEventHandlerOnBladeHitData(ASkylineTorHammer InHammer, FGravityBladeHitData InHit)
	{
		Hammer = InHammer;
		Hit = InHit;
	}
}
