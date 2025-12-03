class AMoonMarketHoldableActor : AMoonMarketInteractableActor
{
	default InteractComp.bUseLazyTriggerShapes = true;
	
	FVector OriginalLocation;
	FRotator OriginalRotation;
	bool bUseSpawnEffect = true;
	bool bResetTransformOnDropped = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		OriginalLocation = ActorLocation;
		OriginalRotation = ActorRotation;
	}

	void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player) override
	{
		Super::OnInteractionStarted(InteractionComponent, Player);
		UMoonMarketHoldableActorEventHandler::Trigger_OnPickup(this, FMoonMarketInteractingPlayerEventParams(Player));
	}

	void OnInteractionStopped(AHazePlayerCharacter Player) override
	{
		auto DropVolume = UMoonMarketPlayerInteractionComponent::Get(InteractingPlayer).DropVolume;
		
		Super::OnInteractionStopped(Player);
		DetachFromActor();

		if(bUseSpawnEffect)
			UMoonMarketHoldableActorEventHandler::Trigger_OnDespawn(this, FMoonMarketInteractingPlayerEventParams(Player));

		if(DropVolume == nullptr || DropVolume.InteractableTag != InteractableTag)
		{
			if(bResetTransformOnDropped)
			{
				SetActorLocationAndRotation(OriginalLocation, OriginalRotation);
			}

			if(bUseSpawnEffect)
				UMoonMarketHoldableActorEventHandler::Trigger_OnRespawn(this, FMoonMarketInteractingPlayerEventParams(Player));
		}
		else
		{
			FHazeTraceSettings TraceSettings = Trace::InitObjectType(EObjectTypeQuery::WorldStatic);
			TraceSettings.UseLine();
			TraceSettings.IgnoreActor(InteractingPlayer);

			FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + FVector::DownVector * 200.0);
			if (Hit.bBlockingHit)
			{
				ActorLocation = Hit.ImpactPoint;

				if(bUseSpawnEffect)
					UMoonMarketHoldableActorEventHandler::Trigger_OnRespawn(this, FMoonMarketInteractingPlayerEventParams(Player));
			}
		}
	}
};