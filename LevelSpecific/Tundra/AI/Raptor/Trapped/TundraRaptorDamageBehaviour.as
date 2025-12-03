
class UTundraRaptorDamageBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	
	UTundraRaptorSettings RaptorSettings;
	UBasicAIHealthComponent HealthComp;
	bool bDamaged;
	FVector Dir;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		RaptorSettings = UTundraRaptorSettings::GetSettings(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		UTundraGrabberVinesResponseComponent GrabberComp = UTundraGrabberVinesResponseComponent::GetOrCreate(Owner);
		GrabberComp.OnDestroyed.AddUFunction(this, n"OnDestroyed");
	}

	UFUNCTION()
	private void OnDestroyed()
	{
		bDamaged = true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if(!bDamaged)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == true)
			return true;
		if(ActiveDuration > RaptorSettings.DamageDuration)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		bDamaged = false;
		HealthComp.TakeDamage(0.4, EDamageType::MeleeBlunt, Game::Mio);
		Dir = Owner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(Owner.ActorLocation + Dir);
		DestinationComp.MoveTowards(Owner.ActorLocation + Dir * -100, 3000);
	}
}