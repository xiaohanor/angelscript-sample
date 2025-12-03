struct FCentipedeBiteTargetingCapabilityActivationParams
{
	UCentipedeBiteResponseComponent TargetBiteComponent = nullptr;
}

class UCentipedeBiteTargetingCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;

	default CapabilityTags.Add(CentipedeTags::Centipede);
	default CapabilityTags.Add(CentipedeTags::CentipedeBite);
	default CapabilityTags.Add(n"BlockedWhileDead");

	UPlayerCentipedeComponent CentipedeComponent;
	UCentipedeBiteComponent CentipedeBiteComponent;
	UPlayerTargetablesComponent TargetablesComponent;

	UCentipedeBiteResponseComponent TargetBiteComponent;

	const float CooldownDuration = 0.1;
	float CooldownTimer = 0.0;

	bool bInCooldown = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Player);
		CentipedeBiteComponent = UCentipedeBiteComponent::Get(Player);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FCentipedeBiteTargetingCapabilityActivationParams& ActivationParams) const
	{
		UCentipedeBiteResponseComponent BiteResponseComponent = TargetablesComponent.GetPrimaryTarget(UCentipedeBiteResponseComponent);
		if (BiteResponseComponent == nullptr)
			return false;

		if (BiteResponseComponent.bDisabledAutoTargeting)
			return false;

		if (BiteResponseComponent.IsDisabledForPlayer(Player))
			return false;

		if (BiteResponseComponent.IsBitten() && !BiteResponseComponent.bAutoTargetWhileBitten)
			return false;

		if (bInCooldown)
			return false;

		ActivationParams.TargetBiteComponent = BiteResponseComponent;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TargetBiteComponent == nullptr)
			return true;

		float SquaredDist = Player.ActorLocation.DistSquared(TargetBiteComponent.WorldLocation);
		if (SquaredDist > Math::Square(TargetBiteComponent.PlayerRange))
			return true;

		if (TargetBiteComponent.bDisabledAutoTargeting)
			return true;

		if (TargetBiteComponent.IsDisabledForPlayer(Player))
			return true;

		if (TargetBiteComponent.IsBitten() && !TargetBiteComponent.bAutoTargetWhileBitten)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCentipedeBiteTargetingCapabilityActivationParams ActivationParams)
	{
		bInCooldown = false;
		CooldownTimer = 0;

		CentipedeBiteComponent.TargetedComponent = TargetBiteComponent = ActivationParams.TargetBiteComponent;

		FCentipedeBiteEventParams Params;
		Params.CentipedeBiteComponent = CentipedeBiteComponent;
		Params.Player = Player;
		UCentipedeEventHandler::Trigger_OnBiteAnticipationStarted(CentipedeComponent.Centipede, Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CentipedeComponent.ClearMovementFacingDirectionOverride(this);
		CentipedeBiteComponent.TargetedComponent = TargetBiteComponent = nullptr;

		bInCooldown = true;

		FCentipedeBiteEventParams Params;
		Params.CentipedeBiteComponent = CentipedeBiteComponent;
		Params.Player = Player;
		UCentipedeEventHandler::Trigger_OnBiteAnticipationStopped(CentipedeComponent.Centipede, Params);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsActive())
			return;

		if (!HasControl())
			return;

		if (!bInCooldown)
			return;

		if (CooldownTimer >= CooldownDuration)
			bInCooldown = false;
		else
			CooldownTimer += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Accelerate to target
		float Alpha = Math::Square(Math::Saturate(ActiveDuration / 0.6));

		FTransform TargetTransform = TargetBiteComponent.GetAdjustedInteractionTransformForPlayer(Player);
		FQuat TargetRotation = FQuat::FastLerp(Player.ActorQuat, TargetTransform.Rotation, Alpha);
		CentipedeComponent.ApplyMovementFacingDirectionOverride(TargetRotation.ForwardVector.GetSafeNormal(), this);
	}
}