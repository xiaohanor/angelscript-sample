class USanctuaryWeeperLightBirdIlluminateCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	ASanctuaryWeeperLightBird LightBird;
	USanctuaryWeeperLightBirdUserComponent UserComp;
	AHazePlayerCharacter Player;

	TArray<AActor> RegisteredHits;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightBird = Cast<ASanctuaryWeeperLightBird>(Owner);
		Player = LightBird.Player;
		UserComp = USanctuaryWeeperLightBirdUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Player.IsPlayerDead())
			return false;

		if (!UserComp.IsTransformed())
			return false;

		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !IsActioning(ActionNames::SecondaryLevelAbility))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Player.IsPlayerDead())
			return true;

		if (!UserComp.IsTransformed())
			return true;

		if (!IsActioning(ActionNames::PrimaryLevelAbility) && !IsActioning(ActionNames::SecondaryLevelAbility))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LightBird.bIsIlluminating = true;
		USanctuaryWeeperLightBirdEventHandler::Trigger_Illuminated(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for (int i = RegisteredHits.Num() - 1; i >= 0; --i)
		{
			auto Actor = RegisteredHits[i];
			if (Actor == nullptr)
				continue;

			auto ResponseComponent = USanctuaryWeeperLightBirdResponseComponent::Get(Actor);
			if (ResponseComponent != nullptr)
				ResponseComponent.Unilluminate(LightBird);
		}
		RegisteredHits.Empty();

		LightBird.bIsIlluminating = false;
		USanctuaryWeeperLightBirdEventHandler::Trigger_Unilluminated(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
		Trace.IgnoreActor(LightBird);
		Trace.IgnoreActor(Game::Mio);
		Trace.IgnoreActor(Game::Zoe);
		Trace.UseSphereShape(LightBird.IlluminationRadius);

		auto OverlapResults = Trace.QueryOverlaps(LightBird.ActorCenterLocation);

		TArray<AActor> ActiveHits;
		for (auto& Overlap : OverlapResults)
		{
			if (Overlap.Actor == nullptr)
				continue;

			if (!RegisteredHits.Contains(Overlap.Actor))
			{
				auto ResponseComponent = USanctuaryWeeperLightBirdResponseComponent::Get(Overlap.Actor);
				if (ResponseComponent != nullptr)
					ResponseComponent.Illuminate(LightBird);
			}

			ActiveHits.AddUnique(Overlap.Actor);
			RegisteredHits.AddUnique(Overlap.Actor);
		}

		for (int i = RegisteredHits.Num() - 1; i >= 0; --i)
		{
			auto Actor = RegisteredHits[i];
			if (Actor == nullptr || ActiveHits.Contains(Actor))
				continue;

			auto ResponseComponent = USanctuaryWeeperLightBirdResponseComponent::Get(Actor);
			if (ResponseComponent != nullptr)
				ResponseComponent.Unilluminate(LightBird);

			RegisteredHits.Remove(Actor);
		}
	}
}