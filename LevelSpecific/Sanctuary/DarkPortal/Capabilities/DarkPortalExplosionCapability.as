struct FDarkPortalExplosionParams
{
	TArray<UDarkPortalResponseComponent> ResponseComponents;
}

class UDarkPortalExplosionCapability : UHazeCapability
{
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortal);
	default CapabilityTags.Add(DarkPortal::Tags::DarkPortalExplosion);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ADarkPortalActor Portal;
	AHazePlayerCharacter Player;
	ULightBirdResponseComponent LightBirdResponse;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Portal = Cast<ADarkPortalActor>(Owner);
		Player = Portal.Player;
		LightBirdResponse = ULightBirdResponseComponent::Get(Portal);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Portal.IsSettled())
			return false;

		if (Portal.AttachResponse != nullptr)
		{
			if (Portal.AttachResponse.bDisableBirdAttach)
				return false;
		}

		if (!LightBirdResponse.IsAttached())
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FDarkPortalExplosionParams& Params) const
	{
		if (ActiveDuration < DarkPortal::Explosion::ExplosionDelay)
			return false;

		QueryOverlappingResponseComponents(Params.ResponseComponents);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FDarkPortalExplosionParams Params)
	{
		// Trigger explosion on all affected response components
		for (auto PortalResponse : Params.ResponseComponents)
		{
			FVector Direction = (PortalResponse.Owner.ActorLocation - PortalResponse.GetOriginLocationForPortal(Portal)).GetSafeNormal();
			PortalResponse.Explode(Portal, Direction);
		}
		
		// Recall exploded portal
		Portal.Recall();

		UDarkPortalEventHandler::Trigger_Exploded(Portal);
	}

	private void QueryOverlappingResponseComponents(TArray<UDarkPortalResponseComponent>& ResponseComponents) const
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceZoe);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		Trace.IgnoreActor(Portal);
		Trace.UseSphereShape(DarkPortal::Explosion::ExplosionRadius);

		auto Overlaps = Trace.QueryOverlaps(Portal.ActorLocation);
		for (auto Overlap : Overlaps.OverlapResults)
		{
			auto PortalResponseComp = UDarkPortalResponseComponent::Get(Overlap.Actor);
			if (PortalResponseComp != nullptr)
				ResponseComponents.AddUnique(PortalResponseComp);
		}
	}
}