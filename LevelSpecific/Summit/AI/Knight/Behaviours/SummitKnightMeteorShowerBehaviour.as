struct FKnightMeteorShowerParams
{
	TArray<USummitKnightAreaDenialSphereComponent> TargetComponents;	
}

class USummitKnightMeteorShowerBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightAreaDenialFireballLauncher Launcher;
	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;
	int NumLaunched;

	TArray<ASummitKnightAreaDenialFireball> Fireballs;
	TArray<USummitKnightAreaDenialSphereComponent> TargetComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		Launcher = USummitKnightAreaDenialFireballLauncher::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);

		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FKnightMeteorShowerParams& OutParams) const
	{
		if (!Super::ShouldActivate())
			return false;
		SetTargets(OutParams.TargetComponents);	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())	
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FKnightMeteorShowerParams Params)
	{
		Super::OnActivated();

		TargetComps = Params.TargetComponents;

		Durations.Telegraph = Settings.MeteorShowerTelegraphDuration;
		Durations.Anticipation = Settings.MeteorShowerAnticipationDuration;
		Durations.Action = Settings.MeteorShowerAttackDuration;
		Durations.Recovery = Settings.MeteorShowerRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::LargeAreaStrike, NAME_None, Durations);
		AnimComp.RequestAction(SummitKnightFeatureTags::LargeAreaStrike, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;
		NumLaunched = 0;
		Fireballs.Empty();

		Sceptre.Equip();
		Blades[0].Unequip();
		Blades[1].Unequip();

		// Slow down circling
		USummitKnightSettings::SetCirclingSpeed(Owner, 0.0, this, EHazeSettingsPriority::Gameplay);

		USummitKnightEventHandler::Trigger_OnTelegraphLargeAreaStrike(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.ClearSettingsByInstigator(this);

		Sceptre.Unequip();
		Blades[0].Equip();
		Blades[1].Equip();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(KnightComp.Arena.Center);

		if (ActiveDuration > LaunchTime)
		{
			UBasicAIProjectileComponent Projectile = Launcher.Launch(Launcher.WorldRotation.ForwardVector * 1000.0);
			auto Fireball = Cast<ASummitKnightAreaDenialFireball>(Projectile.Owner);
			Fireballs.AddUnique(Fireball);
			USummitKnightAreaDenialSphereComponent CurTargetComp = TargetComps[NumLaunched];
			CurTargetComp.Owner.SetActorLocation(KnightComp.GetArenaLocation(CurTargetComp.Owner.ActorLocation));
			Fireball.LaunchAt(CurTargetComp, Launcher);

			NumLaunched++;

			if (NumLaunched < TargetComps.Num())
				LaunchTime += Durations.Action / Math::Max(1.0, float(TargetComps.Num() - 1));
			else 
				LaunchTime = BIG_NUMBER;

			//USummitKnightEventHandler::Trigger_OnLaunchAreaDenialFireball(Owner, FSummitKnightLaunchProjectileParams(Launcher.LaunchLocation));
		}	
	}

	void SetTargets(TArray<USummitKnightAreaDenialSphereComponent>&out OutTargets) const
	{
		OutTargets.Empty();
		TArray<ASummitKnightAreaDenialZone> Zones = TListedActors<ASummitKnightAreaDenialZone>().GetArray();

		// Get a bunch of random zones
		Zones.Shuffle();

		for (ASummitKnightAreaDenialZone Zone : Zones)
		{
			TArray<USummitKnightAreaDenialSphereComponent> ZoneTargets;
			Zone.GetComponentsByClass(ZoneTargets);
			OutTargets.Append(ZoneTargets);
			if (OutTargets.Num() >= Settings.MeteorShowerNumber)
			{
				OutTargets.SetNum(Settings.MeteorShowerNumber);	
				return;
			}
		}
	}
}

