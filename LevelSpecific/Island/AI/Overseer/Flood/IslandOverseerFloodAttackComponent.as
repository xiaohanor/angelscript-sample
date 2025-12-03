event void FOverseerTestEvent();

class UIslandOverseerFloodAttackComponent : USceneComponent
{
	UIslandOverseerHoistComponent HoistComp;
	TArray<UNiagaraComponent> Effects;
	AAIIslandOverseer Overseer;
	bool bFloodRunning;
	bool bPauseOwnerMovement;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetChildrenComponentsByClass(UNiagaraComponent, true, Effects);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		HoistComp = UIslandOverseerHoistComponent::GetOrCreate(Owner);
	}

	void StartEffects()
	{
		for(UNiagaraComponent Effect : Effects)
			Effect.Activate();

		UIslandOverseerEventHandler::Trigger_OnFloodAttackStart(Overseer);
	}

	void StopEffects()
	{
		for(UNiagaraComponent Effect : Effects)
			Effect.Deactivate();

		UIslandOverseerEventHandler::Trigger_OnFloodAttackStop(Overseer);
	}

	void SetSplashOffset(FVector Offset)
	{
		for(UNiagaraComponent Effect : Effects)
			Effect.SetVectorParameter(n"SplashOffset", Offset);
	}

	void StartFlood()
	{
		Overseer.OnFloodStarted.Broadcast();
		bFloodRunning = true;
	}

	void StopFlood()
	{
		Overseer.OnFloodStopped.Broadcast();
		bFloodRunning = false;
	}
}
