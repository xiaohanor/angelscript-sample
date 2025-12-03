struct FWalkerHeadHurtReactionDeactivationParams
{
	AHazePlayerCharacter NewTarget;
}

class UIslandWalkerHeadHurtReactionBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UIslandWalkerHeadComponent HeadComp;
	UIslandWalkerAnimationComponent HeadAnimComp;
	AIslandWalkerHeadStumpTarget Stump;
	AHazePlayerCharacter Shooter;
	UIslandWalkerSettings Settings;
	float LastDamageTime = -BIG_NUMBER;
	float ReactionDuration;
	float HurtEndTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HeadComp = UIslandWalkerHeadComponent::Get(Owner);
		HeadAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UIslandWalkerHeadStumpRoot::Get(Owner).OnStumpTargetSetup.AddUFunction(this, n"OnStumpSetup");
	}

	UFUNCTION()
	private void OnStumpSetup(AIslandWalkerHeadStumpTarget Target)
	{
		Stump = Target;
		Stump.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	UFUNCTION()
	private void OnTakeDamage(AHazePlayerCharacter _Shooter, float RemainingHealth)
	{
		LastDamageTime = Time::GameTimeSeconds;
		if (!TargetComp.IsValidTarget(Shooter))
			Shooter = _Shooter; // New shooter
		else if (_Shooter == Stump.ShieldBreaker)
			Shooter = _Shooter; // Only switch shooter if this was also the one breaking the shield

		if (IsActive())
		{
			AnimComp.RequestSubFeature(SubTagWalkerHeadHurtReaction::Repeat, this);
			HurtEndTime = ActiveDuration + ReactionDuration; 
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (Time::GetGameTimeSince(LastDamageTime) > 0.5)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FWalkerHeadHurtReactionDeactivationParams& OutParams) const
	{
		if (Super::ShouldDeactivate() || 
			(ActiveDuration > HurtEndTime + Settings.HeadHurtReactionRecoverDuration))
		{
			if (ActiveDuration > HurtEndTime)
			{
				if (TargetComp.IsValidTarget(Shooter))
					OutParams.NewTarget = Shooter;
				else
					OutParams.NewTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
			}
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		ReactionDuration = HeadAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::HeadHurtReaction, NAME_None, 0.0);
		AnimComp.RequestFeature(FeatureTagWalker::HeadHurtReaction, NAME_None, EBasicBehaviourPriority::High, this);

		HurtEndTime = ReactionDuration;

		UIslandWalkerSettings::SetHeadTurnDuration(Owner, Settings.HeadHurtReactionRecoverDuration * 0.5, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FWalkerHeadHurtReactionDeactivationParams Params)
	{
		Super::OnDeactivated();
		TargetComp.SetTargetLocal(Params.NewTarget);

		// Change shield color to match other player since we're going to be chasing shooter
		// Ignore this if we're already crashing		
		if ((Stump.Health > Settings.HeadCrashHealthThreshold) && (Stump.ShieldBreaker == Params.NewTarget))
			Stump.SwapShieldBreaker();

		LastDamageTime = -BIG_NUMBER;
		Owner.ClearSettingsByInstigator(this);
		Shooter = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > HurtEndTime)
		{
			// TODO: Might want to add an aggro anim here
			AnimComp.ClearFeature(this);
			DestinationComp.RotateTowards(Shooter);
		}
		else
		{
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
		}
	}
};
