class USummitKnightAcidShieldBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	default CapabilityTags.Add(SummitKnightTags::SummitKnightShield);
	
	AAISummitKnight SummitKnight;
	USummitMeltComponent MeltComp;
	USummitKnightAnimationComponent KnightAnimComp;
	USummitKnightCrystalFieldComponent CrystalFieldComp;
	USummitKnightShieldComponent ShieldComp;
	AHazeActor Instigator;
	USummitKnightDeprecatedSettings KnightSettings;

	float bAcidHitTime = 0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		MeltComp = USummitMeltComponent::GetOrCreate(Owner);
		auto AcidResponseComp = UAcidResponseComponent::GetOrCreate(Owner);
		AcidResponseComp.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		SummitKnight = Cast<AAISummitKnight>(Owner);
		KnightAnimComp = USummitKnightAnimationComponent::GetOrCreate(Owner);
		KnightSettings = USummitKnightDeprecatedSettings::GetSettings(Owner);
		CrystalFieldComp = USummitKnightCrystalFieldComponent::GetOrCreate(Owner);
	}

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{
		bAcidHitTime = Time::GetGameTimeSeconds();
		Instigator = Hit.PlayerInstigator;
		KnightAnimComp.AcidShieldInstigator = Hit.PlayerInstigator;

		if (TargetComp.Target != Hit.PlayerInstigator)
			TargetComp.SetTarget(Hit.PlayerInstigator);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(bAcidHitTime == 0)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(Time::GetGameTimeSince(bAcidHitTime) > KnightSettings.AcidShieldRecoveryDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		MeltComp.DisableMelting(this);
//		AnimComp.RequestFeature(FeatureTagSummitRubyKnight::Shield, SubTagSummitRubyKnightShield::ShieldAcid, EBasicBehaviourPriority::Medium, this);
		Owner.BlockCapabilities(SummitKnightTags::SummitKnightShieldBlocking, this);
		CrystalFieldComp.Show();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		MeltComp.EnableMelting(this);
		bAcidHitTime = 0;
		Owner.UnblockCapabilities(SummitKnightTags::SummitKnightShieldBlocking, this);
		CrystalFieldComp.Hide();
		AnimComp.ClearFeature(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Instigator);
	}
}