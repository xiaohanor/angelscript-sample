class USkylineGeckoTrackingReactionBehaviour : UBasicBehaviour
{	
	// Pause a while to sniff at target's scent
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	
	USkylineGeckoSettings GeckoSettings;
	float ReactionCompleteDuration;
	const FName TeamActionTag = n"TrackingReaction";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GeckoSettings = USkylineGeckoSettings::GetSettings(Owner);
		UHazeActorRespawnableComponent::Get(Owner).OnRespawn.AddUFunction(this, n"OnRespawn");
	}

	UFUNCTION()
	private void OnRespawn()
	{
		// Potentially very high cooldowns (when you want a 'once' behaviour) so reset it.
		Cooldown.Reset();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		
		if (!TargetComp.HasValidTarget())
			return false;

		FVector OwnLoc = Owner.ActorCenterLocation;
		if (!OwnLoc.IsWithinDist(TargetComp.Target.ActorCenterLocation, GeckoSettings.TrackingReactionMaxRange))
			return false;
		if (OwnLoc.IsWithinDist(TargetComp.Target.ActorCenterLocation, GeckoSettings.TrackingReactionMinRange))
			return false;

		if (Math::RandRange(0.0, 100.0) > GeckoSettings.TrackingReactionChance * Time::GetActorDeltaSeconds(Owner))
			return false;

		if (Time::GetGameTimeSince(BehaviourComp.Team.GetLastActionTime(TeamActionTag)) < GeckoSettings.TrackingReactionTeamCooldown)
			return false;

		// Need to be on screen for either player
		if (!SceneView::IsInView(Game::Mio, Owner.ActorCenterLocation) && !SceneView::IsInView(Game::Zoe, Owner.ActorCenterLocation))
			return false;
		
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > ReactionCompleteDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{ 
		Super::OnActivated();
		AnimComp.RequestFeature(LocomotionFeatureAITags::Taunt, SubTagAITaunts::Tracking, EBasicBehaviourPriority::Medium, this, GeckoSettings.TrackingReactionDuration);
		ReactionCompleteDuration = AnimComp.GetAnimDuration(LocomotionFeatureAITags::Taunt, SubTagAITaunts::SpotTarget, GeckoSettings.TrackingReactionDuration);
		BehaviourComp.Team.ReportAction(TeamActionTag);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Math::Min(0.5, ReactionCompleteDuration))
			Cooldown.Set(GeckoSettings.TrackingReactionCooldown); 
	}
}
