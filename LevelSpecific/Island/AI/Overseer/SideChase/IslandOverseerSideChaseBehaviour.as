
class UIslandOverseerSideChaseBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UIslandOverseerSideChaseComponent SideChaseComp;
	UIslandOverseerVisorComponent VisorComp;
	UIslandOverseerPhaseComponent PhaseComp;

	UIslandOverseerSettings Settings;
	FBasicAIAnimationActionDurations Durations;
	AAIIslandOverseer Overseer;
	
	bool bStartedAttacks;
	bool bCompleted;
	bool bStartedTransition;
	FRotator OriginalRotation;
	AIslandOverseerSideChaseStopPoint StopPoint;
	float ImpactTime;
	FHazeAcceleratedFloat AccSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		Overseer = Cast<AAIIslandOverseer>(Owner);
		SideChaseComp = UIslandOverseerSideChaseComponent::GetOrCreate(Owner);
		VisorComp = UIslandOverseerVisorComponent::GetOrCreate(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::GetOrCreate(Owner);
		OriginalRotation = Owner.ActorRotation;
		StopPoint = TListedActors<AIslandOverseerSideChaseStopPoint>().GetSingle();

		auto Response = UIslandRedBlueImpactResponseComponent::Get(Owner);
		Response.OnImpactEvent.AddUFunction(this, n"Impact");
	}

	UFUNCTION()
	private void Impact(FIslandRedBlueImpactResponseParams Data)
	{
		ImpactTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bCompleted)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bStartedAttacks = false;
		AnimComp.RequestFeature(FeatureTagIslandOverseer::Move, EBasicBehaviourPriority::Medium, this);
		Owner.BlockCapabilities(n"Attack", this);
		VisorComp.Open();
		UIslandOverseerEventHandler::Trigger_OnMoveStarted(Owner);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerHealthSettings::SetInvulnerabilityDurationAfterRespawning(Player, 0, this);
			UPlayerHealthSettings::SetRespawnTimer(Player, 3, this);
			UPlayerHealthSettings::SetEnableRespawnTimer(Player, true, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		for(AHazePlayerCharacter Player : Game::Players)
			Player.ClearSettingsByInstigator(this);
		bCompleted = true;
		PhaseComp.SetPhase(EIslandOverseerPhase::TowardsChase);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration > 1 && !bStartedAttacks)
		{
			bStartedAttacks = true;
			Owner.UnblockCapabilities(n"Attack", this);
		}

		AHazePlayerCharacter Target = Game::Mio;
		if(SwitchTarget(Target))
			Target = Target.OtherPlayer;
 
		float Speed = Settings.SideChaseBaseSpeed * Math::Clamp(Owner.ActorLocation.Distance(Target.ActorLocation) / Settings.SideChaseCatchUpDistance, 1, 2);

		AccSpeed.AccelerateTo(Speed, 1, DeltaTime);
		Owner.ActorLocation += Owner.ActorForwardVector * DeltaTime * AccSpeed.Value;

		if(!bStartedTransition && Owner.ActorForwardVector.DotProduct(StopPoint.ActorLocation - Overseer.ProximityKillPointComp.WorldLocation) < 0)
		{
			bStartedTransition = true;
			Overseer.OnSideToTowardsChaseTransition.Broadcast();
		}

		if(Owner.ActorForwardVector.DotProduct(StopPoint.ActorLocation - Owner.ActorLocation) < 0)
		{
			bCompleted = true;
			DeactivateBehaviour();
		}
	}

	private bool SwitchTarget(AHazePlayerCharacter Target)
	{
		if(Target.IsPlayerDead())
			return true;
		if(Target.OtherPlayer.IsPlayerDead())
			return false;
		if(Owner.ActorLocation.Distance(Target.ActorLocation) > Owner.ActorLocation.Distance(Target.OtherPlayer.ActorLocation))
			return true;
		return false;
	}
}