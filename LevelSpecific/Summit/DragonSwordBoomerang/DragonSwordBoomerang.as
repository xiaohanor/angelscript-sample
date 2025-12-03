UCLASS(Abstract)
class ADragonSwordBoomerang : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent SwordOffsetComponent;

	UPROPERTY(DefaultComponent, Attach = SwordOffsetComponent)
	UStaticMeshComponent MioSwordMesh;
	default MioSwordMesh.bGenerateOverlapEvents = false;
	default MioSwordMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default MioSwordMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent, Attach = SwordOffsetComponent)
	UStaticMeshComponent ZoeSwordMesh;
	default ZoeSwordMesh.bGenerateOverlapEvents = false;
	default ZoeSwordMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
	default ZoeSwordMesh.CollisionProfileName = n"NoCollision";

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"DragonSwordBoomerangThrowCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"DragonSwordBoomerangReturnCapability");

	UPROPERTY(DefaultComponent, Attach = MioSwordMesh)
	UNiagaraComponent MioEffectComp;

	UPROPERTY(DefaultComponent, Attach = ZoeSwordMesh)
	UNiagaraComponent ZoeEffectComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedVectorComponent SyncedLocationComp;

	AHazePlayerCharacter ReturnPlayerTarget;

	UDragonSwordCombatUserComponent ReturnPlayerCombatComp;

	TArray<AActor> PreviouslyHitActors;

	FHazeAcceleratedVector AccLocation;
	FVector InitialTargetLocation;

	uint NumberOfHitCrystals = 0;

	bool bIsMovingToInitialTarget = false;
	bool bIsStoppedInPlace = false;
	bool bAutoRecallAfterDuration = true;

	float TimeWhenLastDestroyedTargets;

	void Setup(AHazePlayerCharacter PlayerToReturnTo, FVector TargetLocation)
	{
		ReturnPlayerTarget = PlayerToReturnTo;
		InitialTargetLocation = TargetLocation;
		bIsMovingToInitialTarget = true;
		AccLocation.SnapTo(ActorLocation);
		if (PlayerToReturnTo.IsZoe())
		{
			MioSwordMesh.AddComponentVisualsBlocker(this);
			MioEffectComp.AddComponentVisualsBlocker(this);
		}
		else
		{
			ZoeEffectComp.AddComponentVisualsBlocker(this);
			ZoeSwordMesh.AddComponentVisualsBlocker(this);
		}
	}

	void Recall()
	{
		bIsMovingToInitialTarget = false;
	}

	void TraceForHits(FVector StartLocation, FVector EndLocation, TArray<UDragonSwordCombatResponseComponent>&out HitResponseComponents)
	{
		auto TraceSettings = DragonSwordTrace::GetSphereTraceSettings(100, IgnoreActors = PreviouslyHitActors, bDebugDraw = false);

		if (StartLocation == EndLocation)
		{
			auto OverlapResults = TraceSettings.QueryOverlaps(StartLocation);
			if (OverlapResults.BlockHits.Num() == 0)
				return;

			for (auto Overlap : OverlapResults)
			{
				if (Overlap.Actor == nullptr)
					continue;

				auto ResponseComp = UDragonSwordCombatResponseComponent::Get(Overlap.Actor);
				if (ResponseComp == nullptr)
					continue;

				if (Overlap.Actor.IsA(AStoneBeastCrystalJungle))
					NumberOfHitCrystals++;

				if (NumberOfHitCrystals >= DragonSwordBoomerang::MaxCrystalsBeforeStopping)
					bIsStoppedInPlace = true;

				// ResponseComp.Hit(ReturnPlayerCombatComp, HitData, this);
				PreviouslyHitActors.AddUnique(Overlap.Actor);
				HitResponseComponents.AddUnique(ResponseComp);
			}
		}
		else
		{
			auto HitResults = TraceSettings.QueryTraceMulti(StartLocation, EndLocation);
			if (HitResults.BlockHits.Num() == 0)
				return;

			for (auto HitResult : HitResults)
			{
				if (HitResult.Actor == nullptr)
					continue;

				auto ResponseComp = UDragonSwordCombatResponseComponent::Get(HitResult.Actor);
				if (ResponseComp == nullptr)
					continue;

				if (HitResult.Actor.IsA(AStoneBeastCrystalJungle))
					NumberOfHitCrystals++;

				if (NumberOfHitCrystals >= DragonSwordBoomerang::MaxCrystalsBeforeStopping)
					bIsStoppedInPlace = true;

				// ResponseComp.Hit(ReturnPlayerCombatComp, HitData, this);
				PreviouslyHitActors.AddUnique(HitResult.Actor);
				HitResponseComponents.AddUnique(ResponseComp);
			}
		}
	}

	bool CanDestroyTargets() const
	{
		if (!Network::IsGameNetworked())
			return true;

		// Short delay between target destruction to reduce network calls
		return Time::GetGameTimeSince(TimeWhenLastDestroyedTargets) > 0.1;
	}

	UFUNCTION(CrumbFunction)
	void CrumbHandleHits(const TArray<UDragonSwordCombatResponseComponent>& HitResponseComponents)
	{
		if (HitResponseComponents.Num() == 0)
			return;

		for (auto ResponseComp : HitResponseComponents)
		{
			FDragonSwordHitData HitData;
			HitData.ImpactPoint = ResponseComp.Owner.ActorLocation;
			ResponseComp.Hit(ReturnPlayerCombatComp, HitData, this);
		}
		TimeWhenLastDestroyedTargets = Time::GameTimeSeconds;
	}
};