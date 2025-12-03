class USummitKnightMobileStunnedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Movement);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon);

	UBasicAIHealthComponent HealthComp;
	USummitKnightComponent KnightComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	USummitKnightSettings Settings;

	FVector ImpactLoc;
	FVector PushDir;
	FHazeAcceleratedFloat AccPushForce;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		KnightComp = USummitKnightComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!HealthComp.IsStunned())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		// Note that we do not necessarily allow full animation to play out
		if (ActiveDuration > Settings.SmashCrystalStunnedDuration)
			return true; 
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		CrystalBottom.Shatter();
		CrystalBottom.Retract(this);
		KnightComp.bCanBeStunned.Apply(false, this);
		AnimComp.RequestFeature(SummitKnightFeatureTags::SmashCrystal, EBasicBehaviourPriority::High, this);

		ImpactLoc = Owner.ActorLocation;
		PushDir = (Owner.ActorLocation - Game::Zoe.ActorLocation).GetSafeNormal2D();
		AccPushForce.SnapTo(Settings.SmashCrystalPushedForce);
		USummitKnightSettings::SetRotationDuration(Owner, 1.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		KnightComp.bCanBeStunned.Clear(this);
		HealthComp.ClearStunned();
		CrystalBottom.Deploy(this);
		Owner.ClearSettingsByInstigator(this);
		KnightComp.LastStunnedTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		KnightComp.LastStunnedTime = Time::GameTimeSeconds;

		if (TargetComp.IsValidTarget(Game::Zoe))
		{
			DestinationComp.RotateTowards(Game::Zoe);

			AccPushForce.AccelerateTo(0.0, Settings.HurtReactionDuration, DeltaTime);
			if (Owner.ActorLocation.IsWithinDist2D(ImpactLoc, Settings.SmashCrystalPushedDistance))
				DestinationComp.MoveTowardsIgnorePathfinding(ImpactLoc + PushDir * Settings.SmashCrystalPushedDistance * 2.0, AccPushForce.Value);
		}
	}
}
