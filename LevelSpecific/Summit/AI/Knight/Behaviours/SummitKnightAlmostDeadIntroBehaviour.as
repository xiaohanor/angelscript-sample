class USummitKnightAlmostDeadIntroBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	USummitKnightComponent KnightComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightMobileCrystalBottom CrystalBottom;
	UBasicAIHealthComponent HealthComp;
	USummitKnightSettings Settings;

	FHazeAcceleratedFloat AccSpeed;
	bool bHasCompletedIntro = false;
	float IntroDuration;
	AHazePlayerCharacter Attacker;
	bool bInPosition = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		KnightComp = USummitKnightComponent::Get(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::Get(Owner);
		CrystalBottom = USummitKnightMobileCrystalBottom::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USummitKnightSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bHasCompletedIntro)
			return false;
		return true;	
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > IntroDuration)
		 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bInPosition = false;
		Attacker = Cast<AHazePlayerCharacter>(HealthComp.LastAttacker);
		AccSpeed.SnapTo(0.0);
		KnightComp.bCanBeStunned.Apply(false, this);
		CrystalBottom.Retract(this);
		
		IntroDuration = KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::AlmostDeadRecoil, SummitKnightSubTagsAlmostDead::Start).ScaledPlayLength;
		IntroDuration += KnightAnimComp.GetRequestedAnimation(SummitKnightFeatureTags::AlmostDeadRecoil, SummitKnightSubTagsAlmostDead::End).ScaledPlayLength;
		IntroDuration += Settings.AlmostDeadIntroDurationAdjustment;
		AnimComp.RequestFeature(SummitKnightFeatureTags::AlmostDeadRecoil, EBasicBehaviourPriority::Medium, this);

		USummitKnightEventHandler::Trigger_OnAlmostDeadReaction(Owner);
		USummitKnightSettings::SetRotationDuration(Owner, 1.0, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bHasCompletedIntro = true;
		if (!bInPosition && HasControl())
			CrumbAllowDeath();
		Owner.ClearSettingsByInstigator(this);

		if (!TargetComp.HasValidTarget())
		{
			if (TargetComp.IsValidTarget(Game::Zoe))
				TargetComp.SetTarget(Game::Zoe);
			else if (TargetComp.IsValidTarget(Game::Mio))
				TargetComp.SetTarget(Game::Mio);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Face attacker (or arena center if they're dead)
		if (TargetComp.IsValidTarget(Attacker))
			DestinationComp.RotateTowards(Attacker);
		else
			DestinationComp.RotateTowards(KnightComp.Arena.Center);

		// Move to death position
		float Dist = Owner.ActorLocation.Dist2D(KnightComp.Arena.DeathPosition.WorldLocation);
		if (Dist < 2000.0)
			AccSpeed.AccelerateTo(Math::GetMappedRangeValueClamped(FVector2D(2000.0, 0.0), FVector2D(1000.0, 10.0), Dist), 1.0, DeltaTime);
		else
			AccSpeed.AccelerateTo(Settings.AlmostDeadIntroSpeed, IntroDuration * 0.25, DeltaTime);
		if (Dist > 10.0)
			DestinationComp.MoveTowardsIgnorePathfinding(KnightComp.Arena.DeathPosition.WorldLocation, AccSpeed.Value);				

		if (HasControl() && !bInPosition && (Dist < 500.0))
			CrumbAllowDeath();
	}

	UFUNCTION(CrumbFunction)
	void CrumbAllowDeath()
	{
		bInPosition = true;
		KnightComp.bCanDie.Apply(true, this);
		KnightComp.bCanBeStunned.Clear(this);
		CrystalBottom.Deploy(this);
	}
}


