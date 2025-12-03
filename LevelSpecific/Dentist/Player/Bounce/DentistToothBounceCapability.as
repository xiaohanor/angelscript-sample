struct FDentistToothBounceActivateParams
{
	UDentistToothMovementResponseComponent CurrentResponseComponent = nullptr;
	FVector BounceImpulse = FVector::ZeroVector;
	FHitResult Impact;
};

class UDentistToothBounceCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(Dentist::Tags::BlockedWhileGroundPound);

	default TickGroup = EHazeTickGroup::LastMovement;
	default TickGroupOrder = 100;

	UDentistToothJumpComponent JumpComp;
	UPlayerMovementComponent MoveComp;
	UDentistToothBounceSettings Settings;

	bool bHadImpactLastFrame = false;
	UDentistToothMovementResponseComponent CurrentResponseComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		JumpComp = UDentistToothJumpComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UDentistToothBounceSettings::GetSettings(Player);

		bHadImpactLastFrame = MoveComp.HasAnyValidBlockingImpacts();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FDentistToothBounceActivateParams& Params) const
	{
		if(MoveComp.PreviousHadGroundContact())
			return false;

		if(!MoveComp.HasImpactedGround())
			return false;

		if(MoveComp.PreviousVelocity.DotProduct(FVector::UpVector) > -Settings.MinimumFallingSpeedToBounce)
			return false;

		for(FHitResult GroundImpact : MoveComp.AllGroundImpacts)
		{
			auto MovementResponseComp = UDentistToothMovementResponseComponent::Get(GroundImpact.Actor);
			if(MovementResponseComp == nullptr)
				continue;

			if(!MovementResponseComp.ShouldBounceFromImpact(EDentistToothBounceResponseType::Bounce))
				continue;

			Params.CurrentResponseComponent = MovementResponseComp;
			const FVector BounceNormal = MovementResponseComp.GetBounceNormalForImpactType(GroundImpact, EDentistToothBounceResponseType::Bounce);
			Params.BounceImpulse = GetBounceImpulseFromPreviousVelocity(BounceNormal);
			Params.Impact = GroundImpact;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
			return true;

		if(JumpComp.IsJumping())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FDentistToothBounceActivateParams Params)
	{
		Player.BlockCapabilities(Dentist::Tags::BlockedWhileInBounce, this);

		Bounce(Params.CurrentResponseComponent, Params.BounceImpulse, Params.Impact);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(Dentist::Tags::BlockedWhileInBounce, this);

		CurrentResponseComponent = nullptr;

		UDentistToothEventHandler::Trigger_OnStopBounced(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(MoveComp.PreviousHadGroundContact())
			return;

		for(FHitResult GroundImpact : MoveComp.AllGroundImpacts)
		{
			auto MovementResponseComp = UDentistToothMovementResponseComponent::Get(GroundImpact.Actor);
			if(MovementResponseComp == nullptr)
				continue;

			if(MovementResponseComp == CurrentResponseComponent)
				continue;

			if(!MovementResponseComp.ShouldBounceFromImpact(EDentistToothBounceResponseType::Bounce))
				continue;

			const FVector BounceNormal = MovementResponseComp.GetBounceNormalForImpactType(GroundImpact, EDentistToothBounceResponseType::Bounce);

			CrumbBounce(MovementResponseComp, GetBounceImpulseFromPreviousVelocity(BounceNormal), GroundImpact);
			break;
		}
	}

	private FVector GetBounceImpulseFromPreviousVelocity(FVector BounceNormal) const
	{
		float BounceImpulseMagnitude = Math::Min(0, MoveComp.PreviousVelocity.DotProduct(BounceNormal)) * -Settings.Restitution;
		BounceImpulseMagnitude = Math::Clamp(BounceImpulseMagnitude, 0, Settings.MaxVerticalImpulse);
		return BounceNormal * BounceImpulseMagnitude;
	}

	UFUNCTION(CrumbFunction)
	void CrumbBounce(UDentistToothMovementResponseComponent MovementResponseComp, FVector Impulse, FHitResult Impact)
	{
		Bounce(MovementResponseComp, Impulse, Impact);
	}

	void Bounce(UDentistToothMovementResponseComponent MovementResponseComp, FVector Impulse, FHitResult Impact)
	{
		check(MovementResponseComp != nullptr);
		check(CurrentResponseComponent != MovementResponseComp);

		CurrentResponseComponent = MovementResponseComp;
		Player.AddMovementImpulse(Impulse);

		MovementResponseComp.OnBouncedOn.Broadcast(Player, EDentistToothBounceResponseType::Bounce, Impact);

		FDentistToothBounceOnBounceEventData EventData;
		EventData.MovementResponseComp = MovementResponseComp;
		EventData.Impulse = Impulse;
		EventData.Impact = Impact;
		UDentistToothEventHandler::Trigger_OnBounce(Player, EventData);
	}
};