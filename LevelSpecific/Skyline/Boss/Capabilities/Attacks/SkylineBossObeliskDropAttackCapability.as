class USkylineBossObeliskDropAttackCapability : USkylineBossChildCapability
{
	default CapabilityTags.Add(SkylineBossTags::SkylineBossAttack);
	default CapabilityTags.Add(SkylineBossTags::SkylineBossObeliskDropAttack);

	USkylineBossObeliskDropComponent ObeliskDropComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		ObeliskDropComponent = USkylineBossObeliskDropComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < 10.0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TListedActors<ASkylineBossObeliskDropTarget> ObeliskDropTargets;

		// Find best target
		auto ClosestTargets = Sort::GetClosestActorsToPoint(ObeliskDropTargets.Array, Game::Mio.ActorLocation, 3);

		for (auto ClosestTarget : ClosestTargets)
		{
			SpawnActor(ObeliskDropComponent.ObeliskDropClass, ClosestTarget.ActorLocation, ClosestTarget.ActorRotation);
//			Debug::DrawDebugPoint(ClosestTarget.ActorLocation, 100.0, FLinearColor::Green, 5.0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
}