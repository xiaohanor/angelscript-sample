class UIslandWalkerHeadThruster : UHazeSphereCollisionComponent
{
	default SphereRadius = 40.0;
	default bGenerateOverlapEvents = false;
	default CollisionProfileName = n"BlockOnlyProjectiles";

	bool bDeployed = false;
	bool bIgnited = false;
	bool bVulnerable = false;

	AHazeActor HazeOwner;
	TArray<UNiagaraComponent> Effects;
	UIslandWalkerHeadThrusterTargetableComponent TargetableComp;
	UIslandWalkerHeadThrusterImpactResponseComponent ResponseComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);

		GetChildrenComponentsByClass(UNiagaraComponent, true, Effects);
		for (UNiagaraComponent FX : Effects)
		{
			FX.DeactivateImmediate();
		}
		bIgnited = false;

		TargetableComp = GetChildComponentByClass(UIslandWalkerHeadThrusterTargetableComponent);
		TargetableComp.Disable(this);
		ResponseComp = GetChildComponentByClass(UIslandWalkerHeadThrusterImpactResponseComponent);
		ResponseComp.BlockImpactForPlayer(Game::Mio, this);
		ResponseComp.BlockImpactForPlayer(Game::Zoe, this);
		bVulnerable = false;

		AddComponentVisualsBlocker(this);
		AddComponentCollisionBlocker(this);
		bDeployed = false;
	}

	void Deploy()
	{
		if (bDeployed)
			return;
		bDeployed = true;
		RemoveComponentVisualsBlocker(this);
	}

	void SetVulnerable()
	{
		if (!bDeployed)
			return;
		if (bVulnerable)
			return;
		bVulnerable = true;	
		TargetableComp.Enable(this);
		RemoveComponentCollisionBlocker(this);
		ResponseComp.UnblockImpactForPlayer(Game::Mio, this);
		ResponseComp.UnblockImpactForPlayer(Game::Zoe, this);
	}

	void SetInvulnerable()
	{
		if (!bVulnerable)
			return;
		bVulnerable = false;	
		TargetableComp.Disable(this);
		AddComponentCollisionBlocker(this);
		ResponseComp.BlockImpactForPlayer(Game::Mio, this);
		ResponseComp.BlockImpactForPlayer(Game::Zoe, this);
	}

	void Ignite()
	{
		if (bIgnited)
			return;
		bIgnited = true;
		for (UNiagaraComponent FX : Effects)
		{
			FX.Activate();
		}

		UIslandWalkerHeadEffectHandler::Trigger_OnIgniteThruster(HazeOwner, FIslandWalkerThrusterParams(this));
	}

	void Extinguish()
	{
		if (!bIgnited)
			return;
		bIgnited = false;

		// Josef req: Do not extinguish thrusters. 
		// Note that the entire walker head will be disabled when crashing through the fan at the end of the scenario.
		// for (UNiagaraComponent FX : Effects)
		// {
		// 	FX.Deactivate();
		// }

		// We still want the explosion though to indicate damage
		UIslandWalkerHeadEffectHandler::Trigger_OnExtinguishThruster(HazeOwner, FIslandWalkerThrusterParams(this));
	}

	UFUNCTION(BlueprintCallable)
	void DeactivateEffectsImmediately() // EBP only, thus private
	{
		// Josef req: Do not extinguish thrusters. 
		// Note that the entire walker head will be disabled when crashing through the fan at the end of the scenario.
		// for (UNiagaraComponent FX : Effects)
		// {
		// 	FX.DeactivateImmediate();
		// }
	}
}

class UIslandWalkerHeadThrusterTargetableComponent : UIslandRedBlueTargetableComponent
{
	default TargetShape.Type = EHazeShapeType::Sphere;
	default TargetShape.SphereRadius = 40.0;
	default bTargetWithGrenade = false;
	default bIgnoreActorCollisionForAimTrace = false;
}

class UIslandWalkerHeadThrusterImpactResponseComponent :	UIslandRedBlueImpactResponseComponent
{
	default bIsPrimitiveParentExclusive = true;
}

