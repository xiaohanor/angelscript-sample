class ULightBeamUserComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	bool bIsFiring;
	FVector StartLocation;
	FVector EndLocation;
	
	private AHazePlayerCharacter Player;
	private TArray<AActor> HitActors;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintCallable)
	void StartFiring()
	{
		bIsFiring = true;
		ULightBeamEventHandler::Trigger_StartFiring(Player);
	}

	UFUNCTION(BlueprintCallable)
	void StopFiring()
	{
		bIsFiring = false;
		EndAllHits();
		ULightBeamEventHandler::Trigger_StopFiring(Player);
	}

	UFUNCTION(BlueprintCallable)
	void StartHit(AActor Actor, USceneComponent Component, FVector Location)
	{
		if (Actor == nullptr || HitActors.Contains(Actor))
			return;

		auto ResponseComp = ULightBeamResponseComponent::Get(Actor);

		if (ResponseComp != nullptr)
			ResponseComp.HitBegin(Player);

		HitActors.Add(Actor);

		FLightBeamHitData HitData;
		HitData.Actor = Actor;
		HitData.Component = Component;
		HitData.RelativeLocation = Location;
		ULightBeamEventHandler::Trigger_StartHit(Player, HitData);
	}

	UFUNCTION(BlueprintCallable)
	void EndHit(AActor Actor)
	{
		if (Actor == nullptr || !HitActors.Contains(Actor))
			return;

		auto ResponseComp = ULightBeamResponseComponent::Get(Actor);

		if (ResponseComp != nullptr)
			ResponseComp.HitEnd(Player);

		HitActors.Remove(Actor);

		FLightBeamHitData HitData;
		HitData.Actor = Actor;
		HitData.Component = Actor.RootComponent;
		ULightBeamEventHandler::Trigger_EndHit(Player, HitData);
	}

	UFUNCTION(BlueprintCallable)
	void EndAllHits()
	{
		for (int i = HitActors.Num() - 1; i >= 0; --i)
		{
			auto ResponseComp = ULightBeamResponseComponent::Get(HitActors[i]);

			if (ResponseComp != nullptr)
				ResponseComp.HitEnd(Player);

			// Player.TriggerEffectEvent(n"LightBeam.EndHit");
		}

		HitActors.Empty();
	}

	UFUNCTION(BlueprintCallable)
	bool IsHitting(AActor Actor) const
	{
		return (HitActors.Contains(Actor));
	}

	void UpdateHits(const FVector& TraceStart,
		const FVector& TraceEnd)
	{
		auto Trace = Trace::InitChannel(ETraceTypeQuery::WeaponTracePlayer);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		auto HitResult = Trace.QueryTraceSingle(TraceStart, TraceEnd);

		TArray<AActor> CurrentHits;
		if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
		{
			if (!IsHitting(HitResult.Actor))
			{
				StartHit(HitResult.Actor, 
					HitResult.Component,
					HitResult.ImpactPoint);
			}

			CurrentHits.AddUnique(HitResult.Actor);
		}

		StartLocation = Player.ActorCenterLocation;
		EndLocation = (HitResult.bBlockingHit ? HitResult.ImpactPoint : TraceEnd);

		// auto HitResults = Trace.QueryTraceMulti(TraceStart, TraceEnd);

		// for (auto HitResult : HitResults)
		// {
		// 	if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
		// 	{
		// 		if (!UserComp.IsHitting(HitResult.Actor))
		// 		{
		// 			UserComp.StartHit(HitResult.Actor, 
		// 				HitResult.Component,
		// 				HitResult.ImpactPoint);
		// 		}

		// 		CurrentHits.AddUnique(HitResult.Actor);
		// 	}
		// }

		// UserComp.StartLocation = Player.ActorCenterLocation;
		// UserComp.EndLocation = TraceEnd;

		// End expired hits
		for (int i = HitActors.Num() - 1; i >= 0; --i)
		{
			auto Actor = HitActors[i];

			if (Actor != nullptr && !CurrentHits.Contains(Actor))
				EndHit(Actor);
		}

		// Debug::DrawDebugLine(UserComp.StartLocation,
		// 	UserComp.EndLocation,
		// 	FLinearColor::Yellow,
		// 	LightBeam::BeamRadius);
	}
}