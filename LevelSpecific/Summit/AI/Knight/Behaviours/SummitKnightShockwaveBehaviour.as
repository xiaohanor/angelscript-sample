class USummitKnightShockwaveBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightSettings Settings;
	USummitKnightSceptreComponent Sceptre;
	TArray<USummitKnightBladeComponent> Blades;
	USummitKnightShockwaveLauncher Launcher;
	USummitKnightAnimationComponent KnightAnimComp;
	
	FBasicAIAnimationActionDurations Durations;
	float LaunchTime;

	AHazePlayerCharacter TrackedPlayer;

	float ShockwaveSpeedFactor = 1.0;
	float AnimTimeScale = 1.0;

	USummitKnightShockwaveBehaviour(float AnimPlayRate, float ProjectileSpeedFactor)
	{
		AnimTimeScale = AnimPlayRate;
		ShockwaveSpeedFactor = ProjectileSpeedFactor;
	}

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitKnightSettings::GetSettings(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		Launcher = USummitKnightShockwaveLauncher::Get(Owner);
		Sceptre = USummitKnightSceptreComponent::Get(Owner);
		Owner.GetComponentsByClass(Blades);
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
	void OnActivated()
	{
		Super::OnActivated();

		Blades[0].Equip();

		Durations.Telegraph = Settings.ShockwaveTelegraphDuration;
		Durations.Anticipation = Settings.ShockwaveAnticipationDuration;
		Durations.Action = Settings.ShockwaveActionDuration;
		Durations.Recovery = Settings.ShockwaveRecoverDuration;
		KnightAnimComp.FinalizeDurations(SummitKnightFeatureTags::DualSlash, NAME_None, Durations);
		Durations.ScaleAll(AnimTimeScale * Settings.ShockwaveAnimTimeScale);
		AnimComp.RequestAction(SummitKnightFeatureTags::DualSlash, NAME_None, EBasicBehaviourPriority::Medium, this, Durations);

		LaunchTime = Durations.Telegraph + Durations.Anticipation;

		TrackedPlayer = Game::Zoe;
		if (TargetComp.HasValidTarget() && TargetComp.Target.IsA(AHazePlayerCharacter))
			TrackedPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLoc = TrackedPlayer.ActorLocation;
		if (Game::Mio.ActorLocation.IsWithinDist(Game::Zoe.ActorLocation, Settings.ShockwaveWidth * 0.5))
			TargetLoc = (Game::Mio.ActorLocation + Game::Zoe.ActorLocation) * 0.5;
		if (ActiveDuration < Durations.Telegraph)
			DestinationComp.RotateTowards(TargetLoc);
		
		if (ActiveDuration > LaunchTime)
		{
			LaunchTime = BIG_NUMBER;
			FVector TargetDir = (TargetLoc - Launcher.LaunchLocation).GetSafeNormal2D();
			UBasicAIProjectileComponent Projectile = Launcher.Launch(TargetDir * Settings.ShockwaveMoveSpeed * ShockwaveSpeedFactor);
			Cast<ASummitKnightShockwave>(Projectile.Owner).LaunchAt(TargetLoc);
		}
	}
}

