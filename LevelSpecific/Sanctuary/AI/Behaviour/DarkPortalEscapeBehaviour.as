
class UDarkPortalEscapeBehaviour : UBasicBehaviour
{
	UDarkPortalResponseComponent DarkPortalComp;
	UDarkPortalTargetComponent DarkPortalTargetComp;
	USanctuaryReactionSettings ReactionSettings;

	FTimerHandle EnableTimer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);	
		DarkPortalTargetComp = UDarkPortalTargetComponent::Get(Owner);	
		ReactionSettings = USanctuaryReactionSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())		
			return false;

		if(ReactionSettings.MaxGrabDuration <= 0)
			return false;

		if (!DarkPortalComp.IsGrabbed())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())		
			return true;

		if (!DarkPortalComp.IsGrabbed())
			return true;

		if(ActiveDuration > ReactionSettings.MaxGrabDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		// TODO: Request a feature!
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();		
		Owner.AddMovementImpulse(Owner.ActorVelocity.ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal() * ReactionSettings.EscapeForce);		
	}
}