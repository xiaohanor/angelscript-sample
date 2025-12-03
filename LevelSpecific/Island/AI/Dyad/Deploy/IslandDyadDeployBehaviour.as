
// Move towards enemy
class UIslandDyadDeployBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandDyadDeployComponent DeployComp;
	UIslandDyadLaserComponent LaserComp;
	UBasicAICharacterMovementComponent MoveComp;
	UIslandDyadSettings DyadSettings;
	bool bDeployed;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		DyadSettings = UIslandDyadSettings::GetSettings(Owner);
		DeployComp = UIslandDyadDeployComponent::GetOrCreate(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		LaserComp = UIslandDyadLaserComponent::GetOrCreate(Owner);

		UBasicAIHealthComponent::Get(Owner).OnDie.AddUFunction(this, n"OnDie");
	}

	UFUNCTION()
	private void OnDie(AHazeActor ActorBeingKilled)
	{
		bDeployed = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (bDeployed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (bDeployed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		bDeployed = true;
		LaserComp.bCanConnect = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActiveDuration < 0.25)
			Owner.AddMovementImpulse(DeployComp.DeployDirection * 200);

		if(MoveComp.IsOnAnyGround())
			DeactivateBehaviour();
	}
}