
class USanctuaryDodgerDodgeBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryDodgerTags::SanctuaryDodgerDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UProjectileProximityDetectorComponent ProximityComp;
	UDarkPortalResponseComponent DarkPortalComp;
	USanctuaryDodgerSettings DodgeSettings;

	AActor DodgeProjectile = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		ProximityComp = UProjectileProximityDetectorComponent::Get(Owner);
		ProximityComp.OnProximity.AddUFunction(this, n"OnProjectileProximity");		
		DarkPortalComp = UDarkPortalResponseComponent::Get(Owner);	
		DodgeSettings = USanctuaryDodgerSettings::GetSettings(Owner);	
	}

	UFUNCTION()
	private void OnProjectileProximity(AActor Projectile)
	{
		if (DarkPortalComp.IsGrabbed())
			return;
		
		// Turn off homing capability of any projectile shot at us
		UDarkProjectileMovementComponent DarkProjectileComp = UDarkProjectileMovementComponent::Get(Projectile);
		if (DarkProjectileComp != nullptr)
			DarkProjectileComp.HomingFraction = 0.0;

		DodgeProjectile = Projectile;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (DarkPortalComp.IsGrabbed())
			return false;
		if (DodgeProjectile == nullptr) 
			return false;
		if (Time::GetGameTimeSince(ProximityComp.ProjectileProximityTime) > DodgeSettings.DodgeDuration)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if (DarkPortalComp.IsGrabbed())
			return true;
		if (DodgeProjectile == nullptr) 
			return true;
		if (Time::GetGameTimeSince(ProximityComp.ProjectileProximityTime) > DodgeSettings.DodgeDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		
		USanctuaryDodgerEventHandler::Trigger_StartDodge(Owner);

		// Single impulse for now, test with continuous movetowards as well
		FVector ThreatDirection = (Owner.ActorCenterLocation - DodgeProjectile.ActorLocation).GetSafeNormal();
		FVector DodgeDirection = Math::GetRandomConeDirection(ThreatDirection, PI * 0.5, PI * 0.5);
		Owner.AddMovementImpulse(DodgeDirection * DodgeSettings.DodgeSpeed);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		DodgeProjectile = nullptr;
	}
}