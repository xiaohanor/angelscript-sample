class UBigCrackBirdInNestCapability : UBigCrackBirdBaseCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	bool bInteractAvailable = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Bird.IsPickedUp() || Bird.IsPickupStarted())
			return false;

		if(!Bird.bAttached)
			return false;

		if(Bird.CurrentNest == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Bird.IsPickedUp() || Bird.IsPickupStarted())
			return true;

		if(!Bird.bAttached)
			return true;

		if(Bird.CurrentNest == nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Bird.InteractComp.Disable(this);
		Bird.bAttached = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Bird.TargetNest = nullptr;
		bInteractAvailable = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bInteractAvailable && ActiveDuration > 0.5)
		{
			Bird.InteractComp.Enable(this);
			bInteractAvailable = true;
		}
	
		Owner.SetActorLocation(Math::VInterpConstantTo(Owner.ActorLocation, Bird.CurrentNest.ActorLocation + Bird.NestRelativeLocation, DeltaTime, 700));
	}
};