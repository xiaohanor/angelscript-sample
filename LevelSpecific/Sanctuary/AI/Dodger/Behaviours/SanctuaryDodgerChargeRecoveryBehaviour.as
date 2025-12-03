class USanctuaryDodgerChargeRecoveryBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	FVector Destination;
	bool bSetDestination;
	bool bWasHeadingTowardsDestination;

	UBasicAIHealthComponent HealthComp;
	USanctuaryDodgerGrabComponent GrabComp;
	USanctuaryDodgerSettings DodgerSettings;
	AHazePlayerCharacter PlayerTarget;

	TArray<AHazeActor> AvailableTargets;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GrabComp = USanctuaryDodgerGrabComponent::Get(Owner);
		DodgerSettings = USanctuaryDodgerSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		if(GrabComp.bGrabbing)
		{
			auto GrabbedPlayer = Cast<AHazePlayerCharacter>(GrabComp.GrabbedActor);
			if(GrabbedPlayer != nullptr)
				PlayerTarget = GrabbedPlayer.OtherPlayer;
		}
		else
		{
			PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);
		}

		if(PlayerTarget == nullptr)
		{
			DeactivateBehaviour();
			return;
		}
		bWasHeadingTowardsDestination = false;
		bSetDestination = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(EndRecovery())
			return true;

		return false;
	}

	private void SetDestination()
	{
		if(bSetDestination)
			return;
		Destination = PlayerTarget.ActorLocation + PlayerTarget.ViewRotation.ForwardVector * DodgerSettings.ChargeRecoveryDistance;
		Destination.Z = PlayerTarget.ActorLocation.Z + DodgerSettings.ChargeRecoveryHeight;
		bSetDestination = true;
	}

	private bool EndRecovery() const
	{
		// Past max duration?
		if (ActiveDuration > DodgerSettings.ChargeRecoveryMaxDuration)
			return true;

		// We have been going the right direction, have we passed destination? 
		if (bWasHeadingTowardsDestination && Owner.ActorVelocity.DotProduct(Destination - Owner.ActorLocation) < 0.0)
			return true;

		// Are we close enough already to the destination?
		if(Owner.ActorLocation.IsWithinDist(Destination, 25.0))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target);

		if(ActiveDuration < DodgerSettings.ChargeRecoveryDestinationDelay)
			return;

		SetDestination();

		// Move beyond destination, so we won't stop when coming close
		FVector ToDestDir = (Destination - Owner.ActorLocation).GetSafeNormal();
		FVector BeyondDest = Destination + ToDestDir * (DestinationComp.MinMoveDistance + 80.0);
		DestinationComp.MoveTowards(BeyondDest, DodgerSettings.ChargeRecoverySpeed);		

		if (!bWasHeadingTowardsDestination && (ToDestDir.DotProduct(Owner.ActorVelocity) > 0.0))
			bWasHeadingTowardsDestination = true;
	}
}