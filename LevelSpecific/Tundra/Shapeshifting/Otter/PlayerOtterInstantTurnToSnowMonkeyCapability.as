class UTundraPlayerOtterInstantTurnToSnowMonkeyCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Input;

	default CapabilityTags.Add(TundraShapeshiftingTags::Shapeshifting);
	default CapabilityTags.Add(TundraShapeshiftingTags::ShapeshiftingActivation);
	default CapabilityTags.Add(TundraShapeshiftingTags::SnowMonkeyCeilingClimb);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UTundraPlayerShapeshiftingComponent ShapeshiftComp;
	UPlayerMovementComponent MoveComp;
	UTundraPlayerOtterSettings Settings;
	UTundraPlayerSnowMonkeySettings MonkeySettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		Settings = UTundraPlayerOtterSettings::GetSettings(Player);
		MonkeySettings = UTundraPlayerSnowMonkeySettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;

		if(ShapeshiftComp.ShapeTypeIsBlocked(ETundraShapeshiftShape::Big))
			return false;

		float HitDistance;
		if(!IsCeilingValid(HitDistance))
			return false;

		if(HitDistance < MonkeySettings.CeilingCoyoteMaxVerticalDistance)
			return true;

		if(MoveComp.Velocity.Z > 0.0)
		{
			// Based on calculate maximum height formula: h=v²/(2g)
			float ReachedHeight = Math::Square(MoveComp.Velocity.Z) / (2 * MoveComp.GravityForce);

			if(ReachedHeight < HitDistance)
				return false;
		}
		else
		{
			return false;
		}

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.TundraSetPlayerShapeshiftingShape(ETundraShapeshiftShape::Big, true);
	}

	bool IsCeilingValid(float&out HitDistance) const
    {
		TArray<FVector> Origins;
		Origins.Add(Player.ActorLocation);
		Origins.Add(Player.ActorLocation + MoveComp.HorizontalVelocity.GetSafeNormal() * MonkeySettings.CeilingCoyoteMaxHorizontalDistance);

		for(FVector Origin : Origins)
		{
			FHazeTraceSettings Trace = Trace::InitFromPlayer(Player);
			FHitResult Hit = Trace.QueryTraceSingle(Origin, Origin + FVector::UpVector * Settings.MaxDistanceFromCeilingToShiftToMonkey);
			if(!Hit.bBlockingHit)
				continue;

			auto Comp = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Hit.Actor);

			if(Comp == nullptr)
				continue;

			if(Comp.IsDisabled())
				continue;

			if(!Comp.ComponentIsClimbable(Hit.Component))
				continue;

			if(!Comp.bAllowCoyoteSuckUp)
				continue;

			HitDistance = Hit.Distance;
			return true;
		}

		return false;
    }
}