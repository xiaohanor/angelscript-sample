class UBasicSpotTargetReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	
	float ReactionCompleteDuration;
	const FName TeamActionTag = n"SpotTargetReaction";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
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
		if (!OwnLoc.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.SpotTargetReactionMaxRange))
			return false;
		if (OwnLoc.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.SpotTargetReactionMinRange))
			return false;

		if (Time::GetGameTimeSince(BehaviourComp.Team.GetLastActionTime(TeamActionTag)) < BasicSettings.SpotTargetReactionTeamCooldown)
			return false;

		// Need line of sight
		if (!TargetComp.HasVisibleTarget())
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
		AnimComp.RequestFeature(LocomotionFeatureAITags::Taunt, SubTagAITaunts::SpotTarget, EBasicBehaviourPriority::Medium, this, BasicSettings.SpotTargetReactionDuration);
		ReactionCompleteDuration = AnimComp.GetAnimDuration(LocomotionFeatureAITags::Taunt, SubTagAITaunts::SpotTarget, BasicSettings.SpotTargetReactionDuration);
		BehaviourComp.Team.ReportAction(TeamActionTag);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Math::Min(0.5, ReactionCompleteDuration))
			Cooldown.Set(BasicSettings.SpotTargetReactionCooldown); 
	}
}
