
class UBasicMeleeChargeBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	UBasicAIMeleeWeaponComponent Weapon;
	FVector StartLocation;
	FVector Destination;
	bool bTrackTarget;
	bool bWasHeadingTowardsDestination;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Weapon = UBasicAIMeleeWeaponComponent::Get(Owner);

		devCheck(Weapon != nullptr, "" + Owner.Name + " has a melee charge capability but no weapon! Give them a BasicAIMeleeComponent.");
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BasicSettings.ChargeRange))
			return false;
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		// Start melee attack 
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::ChargeAttack, EBasicBehaviourPriority::Medium, this);
		StartLocation = Owner.ActorLocation;
		Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);
		bTrackTarget = true;
		bWasHeadingTowardsDestination = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Stay in charge anim (when we stop requesting it we will play end anim)
		AnimComp.RequestFeature(LocomotionFeatureAITags::MeleeCombat, SubTagAIMeleeCombat::ChargeAttack, EBasicBehaviourPriority::Medium, this);

		FVector OwnLoc = Owner.ActorLocation;
		if (bTrackTarget)
		{
			// Update destination
			Destination = TargetComp.Target.ActorTransform.TransformPosition(BasicSettings.ChargeOffset);

			// Should we stop following target?
			if (OwnLoc.IsWithinDist(Destination, BasicSettings.ChargeTrackTargetRange))
				bTrackTarget = false;
		}

		// Move beyond destination, so we won't stop when coming close
		FVector ToDestDir = (Destination - OwnLoc).GetSafeNormal();
		FVector BeyondDest = Destination + ToDestDir * (DestinationComp.MinMoveDistance + 80.0);
		DestinationComp.MoveTowards(BeyondDest, BasicSettings.ChargeMoveSpeed);
		DestinationComp.RotateTowards(BeyondDest);

		if (!bWasHeadingTowardsDestination && (ToDestDir.DotProduct(Owner.ActorVelocity) > 0.0))
			bWasHeadingTowardsDestination = true;

		if (ShouldEndCharge())
		{
			// Note that we do this after movement, to preserve velocity
			DeactivateBehaviour();
			return;	
		}
	}

	bool ShouldEndCharge()
	{
		// Past max duration?
		if (ActiveDuration > BasicSettings.ChargeMaxDuration)
			return true;

		if (bWasHeadingTowardsDestination)
		{
			// We have been going the right direction, have we passed destination? 
			if (Owner.ActorVelocity.DotProduct(Destination - Owner.ActorLocation) < 0.0)
				return true;
		}

		return false;
	}
}

