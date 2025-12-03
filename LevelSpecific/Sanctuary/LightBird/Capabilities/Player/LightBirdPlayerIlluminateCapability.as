class ULightBirdPlayerIlluminateCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(LightBird::Tags::LightBird);
	default CapabilityTags.Add(LightBird::Tags::LightBirdIlluminate);

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 150;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	ULightBirdUserComponent UserComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	TArray<AActor> Illuminati;

	float LastActivationTime = -BIG_NUMBER;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UserComp = ULightBirdUserComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!UserComp.Companion.CanIlluminate())
			return false;
		if (UserComp.Companion.MustIlluminate())
			return true;		

		if (UserComp.State == ELightBirdState::Lantern)
		{
			return true;
		}
		else if (UserComp.State == ELightBirdState::Attached)
		{
			if (!IsActioning(ActionNames::SecondaryLevelAbility))
				return false;
			if (!UserComp.AttachedTargetData.IsValid())
				return false;
			if (Time::GetRealTimeSince(LastActivationTime) < 0.33)
				return false;
			return true;
		}
		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// If false, the bool has been consumed
		if (!UserComp.bIsIlluminating)
			return true;

		if (!UserComp.Companion.CanIlluminate())
			return true;
		if (UserComp.Companion.MustIlluminate())
			return false;		

		if (UserComp.State == ELightBirdState::Lantern)
		{
			return false;
		}
		else
		{
			if (UserComp.State != ELightBirdState::Attached)
				return true;
			if (!UserComp.AttachedTargetData.IsValid())
				return true;
			if (!IsActioning(ActionNames::SecondaryLevelAbility))
				return true;	
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UserComp.bIsIlluminating = true;
		LastActivationTime = Time::RealTimeSeconds;

		if (UserComp.AttachedWantsExclusivity())
		{
			UserComp.AttachResponse.Illuminate();

			// We only need to keep track of the illuminated ones on the control side.
			if (HasControl())
				Illuminati.Add(UserComp.AttachResponse.Owner);
		}

		if (UserComp.Companion != nullptr)
			ULightBirdEventHandler::Trigger_Illuminated(UserComp.Companion);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UserComp.bIsIlluminating = false;

		if (HasControl())
		{
			TArray<ULightBirdResponseComponent> UnilluminateComps;
			for (int i = Illuminati.Num() - 1; i >= 0; --i)
			{
				auto Actor = Illuminati[i];
				if (Actor == nullptr)
					continue;

				auto ResponseComponent = ULightBirdResponseComponent::Get(Actor);
				if (ResponseComponent != nullptr && !ResponseComponent.IsListener())
					UnilluminateComps.Add(ResponseComponent);
			}
			Illuminati.Empty();
			if (UnilluminateComps.Num() > 0)
				CrumbUnilluminate(UnilluminateComps);
		}

		if (UserComp.Companion != nullptr)
			ULightBirdEventHandler::Trigger_Unilluminated(UserComp.Companion);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl() && !UserComp.AttachedWantsExclusivity())
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
			Trace.IgnoreActor(Game::Mio);
			Trace.IgnoreActor(Game::Zoe);
			Trace.UseSphereShape(LightBird::Illumination::Radius);

			auto OverlapResults = Trace.QueryOverlaps(Player.FocusLocation);

			TArray<AActor> ActiveHits;
			TArray<ULightBirdResponseComponent> IlluminateComps;
			for (auto& Overlap : OverlapResults)
			{
				if (Overlap.Actor == nullptr)
					continue;

				ActiveHits.AddUnique(Overlap.Actor);
				if (!Illuminati.Contains(Overlap.Actor))
				{
					auto ResponseComponent = ULightBirdResponseComponent::Get(Overlap.Actor);
					if (ResponseComponent != nullptr && !ResponseComponent.IsListener())
					{
						if (ResponseComponent == UserComp.AttachResponse || ResponseComponent.bCanBeIlluminatedFromProximity)
						{
							IlluminateComps.Add(ResponseComponent);
							Illuminati.Add(Overlap.Actor);
						}
					}
				}
			}
			if (IlluminateComps.Num() > 0)
				CrumbIlluminate(IlluminateComps);

			TArray<ULightBirdResponseComponent> UnIlluminateComponents;
			for (int i = Illuminati.Num() - 1; i >= 0; --i)
			{
				auto Actor = Illuminati[i];
				if (Actor == nullptr)
				{
					// Streamed out actor, clean
					Illuminati.RemoveAt(i);
					continue;
				}
				if (ActiveHits.Contains(Actor))
					continue; // Still illuminated

				// No longer illuminated
				auto ResponseComponent = ULightBirdResponseComponent::Get(Actor);
				if (ResponseComponent != nullptr && !ResponseComponent.IsListener())
					UnIlluminateComponents.Add(ResponseComponent);
				Illuminati.RemoveAt(i);
			}
			if (UnIlluminateComponents.Num() > 0)
				CrumbUnilluminate(UnIlluminateComponents);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbIlluminate(TArray<ULightBirdResponseComponent> ResponseComponents)
	{
		for (ULightBirdResponseComponent ResponseComponent : ResponseComponents)	
		{
			if (ResponseComponent != nullptr)
				ResponseComponent.Illuminate();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbUnilluminate(TArray<ULightBirdResponseComponent> ResponseComponents)
	{
		for (ULightBirdResponseComponent ResponseComponent : ResponseComponents)	
		{
			if (ResponseComponent != nullptr)
				ResponseComponent.Unilluminate();
		}
	}
}