class UCentipedeBiteComponent : UActorComponent
{
	UPROPERTY(NotEditable, BlueprintHidden)
	private UCentipedeBiteResponseComponent BittenComponent = nullptr;

	AHazePlayerCharacter PlayerOwner;

	access BiteCapability = private, UCentipedeBiteCapability, UCentipedeBiteVisualsCapability, UCentipedeBiteActivationCapability;
	access : BiteCapability bool bBiting = false;

	access : BiteCapability float InRangeFraction = 0.0;

	private TInstigated<bool> InstigatedDoubleInteraction;
	default InstigatedDoubleInteraction.SetDefaultValue(false);

	private TInstigated<UCentipedeBiteResponseComponent> InstigatedPendingBiteComponent;
	default InstigatedPendingBiteComponent.SetDefaultValue(nullptr);

	access BiteTargeting = private, UCentipedeBiteTargetingCapability;
	access : BiteTargeting UCentipedeBiteResponseComponent TargetedComponent = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	void Bite(UCentipedeBiteResponseComponent BiteResponseComponent)
	{
		if (BiteResponseComponent == nullptr) // it is already destroyed. If we end up with undead moles, remove this to get assert when it happens. But I think mole should become dead on both sides :)
			return;
		BittenComponent = BiteResponseComponent;

		FCentipedeBiteEventParams BiteParams;
		BiteParams.CentipedeBiteComponent = this;
		BiteParams.Player = Cast<AHazePlayerCharacter>(Owner);

		BittenComponent.OnCentipedeBiteStarted.Broadcast(BiteParams);
	}

	void StopBiting()
	{
		if (BittenComponent != nullptr)
		{
			FCentipedeBiteEventParams BiteParams;
			BiteParams.CentipedeBiteComponent = this;
			BiteParams.Player = Cast<AHazePlayerCharacter>(Owner);

			BittenComponent.OnCentipedeBiteStopped.Broadcast(BiteParams);

			BittenComponent = nullptr;
		}
	}

bool GetBiteActionStarted(const UHazeCapability BiteCapability) const
	{
#if !RELEASE
		auto DebugMovementComponent = UPlayerCentipedeDebugMovementComponent::GetOrCreate(Owner);
		if (DebugMovementComponent != nullptr && DebugMovementComponent.IsActive())
			return DebugMovementComponent.GetBitingStarted();
#endif

		bool bActionStarted = BiteCapability.WasActionStarted(ActionNames::PrimaryLevelAbility);

		return bActionStarted;
	}

	bool GetBiteActioning(const UHazeCapability BiteCapability) const
	{
#if !RELEASE
		auto DebugMovementComponent = UPlayerCentipedeDebugMovementComponent::GetOrCreate(Owner);
		if (DebugMovementComponent != nullptr && DebugMovementComponent.IsActive())
			return DebugMovementComponent.GetIsBiting();
#endif

		bool bBiteActioning = BiteCapability.IsActioning(ActionNames::PrimaryLevelAbility);

		return bBiteActioning;
	}

	UCentipedeBiteResponseComponent GetTargetedComponent() const
	{
		return TargetedComponent;
	}

	FVector GetBiteLocation() const
	{
		return PlayerOwner.ActorLocation + PlayerOwner.ActorForwardVector * Centipede::PlayerMeshMandibleOffset;
	}

	void ApplyDoubleInteractionBite(FInstigator Instigator, EInstigatePriority Priority = EInstigatePriority::Normal)
	{
		InstigatedDoubleInteraction.Apply(true, Instigator, Priority);
	}

	void ClearDoubleInteractionBite(FInstigator Instigator)
	{
		InstigatedDoubleInteraction.Clear(Instigator);
	}

	bool IsDoubleInteractionBite() const
	{
		return InstigatedDoubleInteraction.Get();
	}

	void ApplyPendingBite(UCentipedeBiteResponseComponent BiteResponseComponent, FInstigator Instigator)
	{
		InstigatedPendingBiteComponent.Apply(BiteResponseComponent, Instigator);
	}

	void ClearPendingBite(FInstigator Instigator)
	{
		InstigatedPendingBiteComponent.Clear(Instigator);
	}

	UCentipedeBiteResponseComponent GetPendingBiteResponseComponent() const
	{
		return InstigatedPendingBiteComponent.Get();
	}

	// True if jaw is closed
	UFUNCTION(BlueprintPure)
	bool IsBiting()
	{
		return bBiting;
	}

	// True if jaw is closed and centipede caught something
	UFUNCTION(BlueprintPure)
	bool IsBitingSomething() const
	{
		return BittenComponent != nullptr;
	}

	// True if player is biting this specific component
	UFUNCTION(BlueprintPure)
	bool IsBitingComponent(const UCentipedeBiteResponseComponent BiteResponseComponent) const
	{
		return BittenComponent == BiteResponseComponent;
	}

	UFUNCTION()
	UCentipedeBiteResponseComponent GetBittenComponent() const
	{
		return BittenComponent;
	}

	UFUNCTION()
	float GetInRangeFraction() const
	{
		return InRangeFraction;
	}

	UFUNCTION()
	bool IsInBitingRange() const
	{
		return InRangeFraction > 0.0;
	}

	void BiteSnapToLocation(FVector TargetLocation, FVector TargetDirection, float Duration)
	{
		if (HasControl())
		{
			CrumbBiteSnapToLocation(TargetLocation, TargetDirection, Duration);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbBiteSnapToLocation(FVector TargetLocation, FVector TargetDirection, float Duration)
	{
		PlayerOwner.SmoothTeleportActor(TargetLocation, FRotator::MakeFromXZ(TargetDirection.GetSafeNormal(), FVector::UpVector), this, Duration);
	}
}