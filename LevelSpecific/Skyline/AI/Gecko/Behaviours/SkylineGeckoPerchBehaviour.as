// Backup behaviour when waiting to attack Zoe with no need to reposition 
class USkylineGeckoPerchBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	USkylineGeckoSettings Settings;
	USkylineGeckoComponent GeckoComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineGeckoSettings::GetSettings(Owner); 
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		// Zoe only!
		if (TargetComp.Target != Game::Zoe)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if (Settings.bAllowBladeHitsWhenPerching)
		{
			// Allow blade hits if perching on the ceiling. 
			if (Owner.ActorUpVector.DotProduct(FVector::UpVector) < -0.866)
				GeckoComp.bAllowBladeHits.Apply(true, this);
		}

		if (TargetComp.GentlemanComponent != nullptr)
		{
			// Are we waiting for permission to make a ground charge?
			if (GeckoComp.IsAtGroundPosition(Settings.GroundPositioningDoneRange + 40.0))
				TargetComp.GentlemanComponent.ClaimToken(GeckoToken::Grounded, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GeckoComp.bAllowBladeHits.Clear(this);

		if ((TargetComp.GentlemanComponent != nullptr) && TargetComp.GentlemanComponent.IsClaimingToken(GeckoToken::Grounded, Owner))
			TargetComp.GentlemanComponent.ReleaseToken(GeckoToken::Grounded, Owner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Stay in place, tracking Zoe
		DestinationComp.RotateTowards(Game::Zoe);

		// Release any perch we're no longer at
		if (GeckoComp.PerchPos.IsValid() && !GeckoComp.IsAtPerch(Settings.PerchPositioningDoneRange))
			GeckoComp.PerchPos.Release();
	}
}
