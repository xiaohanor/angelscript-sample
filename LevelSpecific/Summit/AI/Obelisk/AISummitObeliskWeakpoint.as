class AAISummitObeliskWeakpoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UCapsuleComponent Root;
	default Root.SetCollisionObjectType(ECollisionChannel::EnemyCharacter);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UAcidTailBreakableComponent AcidTailBreakComp;
	default AcidTailBreakComp.WeakenDuration = 3.0;
	default AcidTailBreakComp.AcidHitsNeededToWeaken = 6;
	default AcidTailBreakComp.TimeUntilRestore = 6.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidTailBreakComp.DisableAcidWeaken(this);
		AcidTailBreakComp.OnWeakenedByAcid.AddUFunction(this, n"OnWeakenedByAcid");
		AcidTailBreakComp.OnWeakenRestored.AddUFunction(this, n"OnWeakenRestored");
		AcidTailBreakComp.OnBrokenByTail.AddUFunction(this, n"OnBrokenByTail");
	}

	void ActivateObeliskWeakpoint()
	{
		AcidTailBreakComp.EnableAcidWeaken(this);
	}

	UFUNCTION()
	void OnWeakenedByAcid()
	{
		BP_OnWeakenedByAcid();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakenedByAcid() {}

	UFUNCTION()
	void OnWeakenRestored()
	{
		BP_OnWeakenRestored();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnWeakenRestored() {}
	
	UFUNCTION()
	void OnBrokenByTail(FOnBrokenByTailParams Params)
	{
		SetActorHiddenInGame(true);
		Root.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		FSummitWeakpointDeathParams EffectParams;
		EffectParams.Location = ActorCenterLocation;
		EffectParams.Rotation = ActorRotation;
		UAISummitObeliskWeakpointEffectsHandler::Trigger_DestroyWeakpoint(this, EffectParams);
	}
}