class USummitCrystalSkullTargetingBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	AHazePlayerCharacter ThreateningDragonRider;
	USummitCrystalSkullArmourComponent ArmourComp;
	USummitCrystalSkullSettings FlyerSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		ArmourComp = USummitCrystalSkullArmourComponent::Get(Owner);
		ThreateningDragonRider = Game::Zoe;
		if (ArmourComp != nullptr)
			ThreateningDragonRider  = Game::Mio;
		Owner.SetActorControlSide(ThreateningDragonRider);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		// Hack, should be handled by seperate behaviour and we should have separate compounds for when armoured and not.
		if ((ArmourComp == nullptr) || ArmourComp.Armour == nullptr)
			return;

		if (!ArmourComp.HadArmour(3.0) && (TargetComp.Target == Game::Mio))
		{
			ThreateningDragonRider = Game::Zoe;
			TargetComp.SetTarget(ThreateningDragonRider);
		}
		else if (ArmourComp.HasArmour() && (TargetComp.Target == Game::Zoe))
		{
			ThreateningDragonRider = Game::Mio;
			TargetComp.SetTarget(ThreateningDragonRider);
		}
		else if (!TargetComp.HasValidTarget() && (ArmourComp.Armour.HitCount > 0))
		{
			// So we get a target when hit by acid outside of detection range
			ThreateningDragonRider = Game::Mio;
			TargetComp.SetTarget(ThreateningDragonRider);
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (TargetComp.HasValidTarget())
			return false;
		if (!ThreateningDragonRider.ActorLocation.IsWithinDist(Owner.ActorLocation, FlyerSettings.TargetingRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		TargetComp.SetTarget(ThreateningDragonRider);
		DeactivateBehaviour();
	}
}

