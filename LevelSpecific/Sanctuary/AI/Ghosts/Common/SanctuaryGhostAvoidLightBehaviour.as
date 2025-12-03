class UElementalStingerAvoidLightBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(SanctuaryGhostCommonTags::SanctuaryGhostDarkPortalBlock);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UBasicAICharacterMovementComponent MoveComp;
	USanctuaryGhostCommonSettings GhostCommonSettings;
	AHazeCharacter Ghost;

	AActor AvoidBird = nullptr;
	bool bFlipDir;
	float FlipTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Ghost = Cast<AHazeCharacter>(Owner);
		MoveComp = UBasicAICharacterMovementComponent::Get(Owner);
		GhostCommonSettings = USanctuaryGhostCommonSettings::GetSettings(Owner);		

		auto LightBirdResponseComp = ULightBirdResponseComponent::Get(Owner);
		LightBirdResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		LightBirdResponseComp.OnUnilluminated.AddUFunction(this, n"OnUnilluminated");
	}

	UFUNCTION()
	private void OnUnilluminated()
	{
		AvoidBird = nullptr;
	}

	UFUNCTION()
	private void OnIlluminated()
	{
		// AvoidBird = Bird;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (AvoidBird == nullptr) 
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		USanctuaryGhostCommonEventHandler::Trigger_OnDodge(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AvoidBird = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Time::GetGameTimeSince(FlipTime) > 2)
			bFlipDir = false;

		if (AvoidBird == nullptr) 
		{
			if(MoveComp.Velocity.Size() > 1000)
				Owner.SetActorVelocity(Owner.ActorVelocity*0.8);
			else
				DeactivateBehaviour();
			return;	
		}

		FVector DodgeDirection = (Owner.ActorCenterLocation - AvoidBird.ActorLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		if(bFlipDir)
			DodgeDirection *= -1;
		FVector DodgeLocation = Owner.ActorLocation + DodgeDirection * 100;
		DestinationComp.MoveTowards(DodgeLocation, GhostCommonSettings.DodgeSpeed);

		if(DestinationComp.MoveFailed())
		{
			bFlipDir = !bFlipDir;
			FlipTime = Time::GetGameTimeSeconds();
		}
	}
}