class USwarmDroneHijackEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(Category = "VFX")
	UNiagaraSystem HijackDiveEffect;

	UPROPERTY(NotEditable, NotVisible, Transient)
	TArray<UNiagaraComponent> ActiveDiveEffects;

	UPROPERTY(NotEditable)
	UPlayerSwarmDroneComponent PlayerSwarmDroneComponent;

	UPROPERTY(NotEditable)
	UPlayerSwarmDroneHijackComponent PlayerSwarmDroneHijackComponent;

	TArray<FVector> BotLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerSwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Owner);
		PlayerSwarmDroneHijackComponent = UPlayerSwarmDroneHijackComponent::Get(Owner);
		BotLocations.SetNum(SwarmDrone::DeployedBotCount);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = ActiveDiveEffects.Num() - 1; i >= 0; i--)
		{
			UNiagaraComponent DiveEffect = ActiveDiveEffects[i];
			if (DiveEffect != nullptr)
			{
				if (DiveEffect.IsActive())
				{
					TickHijackDiving(ActiveDiveEffects[i], DeltaTime);
				}
				else
				{
					DiveEffect.DestroyComponent(this);
					ActiveDiveEffects.RemoveAt(i);
				}
			}
		}
	}

	void TickHijackDiving(UNiagaraComponent DiveEffectComponent, const float& DeltaTime)
	{
		// Feed actor transform into effect
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			BotLocations[i] = PlayerSwarmDroneComponent.SwarmBots[i].ActorLocation;
			NiagaraDataInterfaceArray::SetNiagaraArrayVector(DiveEffectComponent, n"Locations", BotLocations);
		}
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHijackDiveStart(FSwarmDroneHijackDiveParams DiveParams)
	{
		// Spawn effect and save reference
		if (HijackDiveEffect != nullptr)
		{
			UNiagaraComponent HijackDiveEffectComponent = Niagara::SpawnLoopingNiagaraSystemAttached(HijackDiveEffect, Owner.RootComponent);
			HijackDiveEffectComponent.SetNiagaraVariableFloat("Duration", DiveParams.DiveDuration);
			HijackDiveEffectComponent.SetNiagaraVariableFloat("Duration_FadeIn", DiveParams.BlendTime);

			ActiveDiveEffects.Add(HijackDiveEffectComponent);
		}
	};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHijackDiveEnd()
	{
		if (!ActiveDiveEffects.IsEmpty())
		{
			// Smooth-deactivate oldest effect
			UNiagaraComponent DiveEffectComponent = ActiveDiveEffects[0];
			if (DiveEffectComponent != nullptr)
			{
				DiveEffectComponent.Deactivate();
			}
			else
			{
				// Shouldn't happen, but remove nullref if so
				ActiveDiveEffects.RemoveAt(0);
			}
		}
	};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHijackStart() {};

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHijackEnd() {};
}