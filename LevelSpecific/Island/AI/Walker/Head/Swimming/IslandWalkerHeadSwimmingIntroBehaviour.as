class UIslandWalkerHeadSwimmingIntroBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	AIslandWalkerArenaLimits Arena;
	UIslandWalkerSettings Settings;
	UBasicAIHealthComponent HealthComp;
	UIslandWalkerHeadComponent HeadComp;
	AIslandWalkerHeadStumpTarget Stump;
	bool bCompletedIntro = false;
	float DiveCompleteTime; 
	AHazePlayerCharacter TrackTarget;
	float SwapTrackTargetTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Arena = TListedActors<AIslandWalkerArenaLimits>().GetSingle();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bCompletedIntro)
			return false;
		if (Arena == nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > DiveCompleteTime)
			return true;
		return false;
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (HealthComp.CurrentHealth < Settings.HeadSwimmingCrashHealthThreshold + 0.1)
			HealthComp.SetCurrentHealth(Settings.HeadSwimmingCrashHealthThreshold + 0.1);

		DiveCompleteTime = 20.0;
		Stump.IgnoreDamage();
		if (Stump.ShieldBreaker == TargetComp.Target)
			Stump.SwapShieldBreaker();
		
		HeadComp.bFinDeployed = true;
		TrackTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (TrackTarget == nullptr)
			TrackTarget = Game::Mio;
		SwapTrackTargetTime = Math::RandRange(3.0, 5.0);

		// We're now set up to start another round of head escaping
		HeadComp.bHeadEscapeSuccess = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bCompletedIntro = true;
		Stump.AllowDamage();
		HeadComp.bFinDeployed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Dive to below center of pool and stay a while to ponder the mysteries of the universe
		FVector DiveLoc = Arena.GetAtFloodedPoolDepth(Arena.ActorLocation, Settings.SwimmingIntroDiveDepth);
		if (!Owner.ActorLocation.IsWithinDist(DiveLoc, 400.0)) 
			DestinationComp.MoveTowardsIgnorePathfinding(DiveLoc, Settings.SwimmingIntroMoveSpeed); 
		else if (DiveCompleteTime > ActiveDuration + Settings.SwimmingIntroDivePause) 
			DiveCompleteTime = ActiveDuration + Settings.SwimmingIntroDivePause; 

		if ((ActiveDuration > SwapTrackTargetTime) && TargetComp.IsValidTarget(TrackTarget.OtherPlayer))
		{
			TrackTarget = TrackTarget.OtherPlayer;
			SwapTrackTargetTime = ActiveDuration + Math::RandRange(3.0, 5.0);
		}
	}
}