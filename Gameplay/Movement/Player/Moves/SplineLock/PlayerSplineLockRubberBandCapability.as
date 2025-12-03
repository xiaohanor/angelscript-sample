class UPlayerSplineLockRubberBandCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"SplineLock");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	default DebugCategory = n"Movement";

	UPlayerMovementComponent MoveComponent;
	UPlayerSplineLockComponent SplineLockComponent;
	UPlayerSplineLockComponent OtherPlayerSplineLockComponent;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComponent = UPlayerMovementComponent::Get(Player);
		SplineLockComponent = UPlayerSplineLockComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SplineLockComponent.IsUsingRubberBanding())
			return false;

		if(!SplineLockComponent.HasActiveSplineLock())
			return false;

		if(SplineLockComponent.IsEnteringSpline())
			return false;

		auto TempOtherPlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player.OtherPlayer);
		if(TempOtherPlayerSplineLockComponent == nullptr)
			return false;

		if(!TempOtherPlayerSplineLockComponent.HasActiveSplineLock())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SplineLockComponent.IsUsingRubberBanding())
			return true;

		if(!SplineLockComponent.HasActiveSplineLock())
			return true;

		if(SplineLockComponent.IsEnteringSpline())
			return true;

		if(OtherPlayerSplineLockComponent == nullptr)
			return true;

		if(!OtherPlayerSplineLockComponent.HasActiveSplineLock())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		OtherPlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		MoveComponent.ClearMoveSpeedMultiplier(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const FSplinePosition MySplinePosition = SplineLockComponent.GetSplinePosition();
		const FSplinePosition OtherSplinePosition = OtherPlayerSplineLockComponent.GetSplinePosition();
		const FPlayerSplineLockSettings Settings = SplineLockComponent.GetCurrentSettings();
		const FHazeRange Ranges = Settings.RubberBandSettings.Ranges;
		const FHazeRange SpeedMultipliers = Settings.RubberBandSettings.SpeedMultipliers;
		const FVector DeltaToOtherPlayer = OtherSplinePosition.WorldLocation - MySplinePosition.WorldLocation;

		bool bIAmAhead = true;
		if(MySplinePosition.IsForwardOnSpline())
			bIAmAhead = MySplinePosition.CurrentSplineDistance > OtherSplinePosition.CurrentSplineDistance;
		else
			bIAmAhead = MySplinePosition.CurrentSplineDistance < OtherSplinePosition.CurrentSplineDistance;

		float DistanceBetweenUs = Math::Abs(MySplinePosition.CurrentSplineDistance - OtherSplinePosition.CurrentSplineDistance) - Ranges.Min;
		DistanceBetweenUs = Math::Clamp(DistanceBetweenUs, 0, Ranges.Max - Ranges.Min);

		float Multiplier = 1.0;
		if(bIAmAhead)
		{
			// If we are running toward the other player
			// while we are ahead, we flip the input
			if(MoveComponent.MovementInput.DotProduct(DeltaToOtherPlayer) > KINDA_SMALL_NUMBER)
				bIAmAhead = !bIAmAhead;
		}
		else
		{
			// if we are behind and is trying to move away
			// from the other player, we flip the input
			if(MoveComponent.MovementInput.DotProduct(DeltaToOtherPlayer) < -KINDA_SMALL_NUMBER)
				bIAmAhead = !bIAmAhead;
		}
		
		// Apply the rubber band speed
		if(DistanceBetweenUs > Ranges.Min && Ranges.Max > Ranges.Min)
		{
			float DistanceAlpha = DistanceBetweenUs / (Ranges.Max - Ranges.Min);
			if(bIAmAhead)
				Multiplier = SpeedMultipliers.Lerp(1.0 - DistanceAlpha);
			else
				Multiplier = SpeedMultipliers.Lerp(DistanceAlpha);
		}

		MoveComponent.ApplyMoveSpeedMultiplier(Multiplier, this, EInstigatePriority::Low);
	}
};