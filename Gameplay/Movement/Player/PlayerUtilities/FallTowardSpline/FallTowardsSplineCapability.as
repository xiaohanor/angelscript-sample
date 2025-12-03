
class UFallTowardsSplineComponent : UActorComponent
{
	UHazeSplineComponent Spline;
	float GuideRadius = 0;
}

// class UTestCapability : UPlayerAirMotionCapability
// {
// 	UFUNCTION(BlueprintOverride)
// 	void Setup() override
// 	{
// 		Super::Setup();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const override
// 	{
// 		return Super::ShouldActivate();
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const override
// 	{
// 		return Super::ShouldDeactivate();
// 	}
// }

/**
 * Steer the player toward a spline if we are falling
 */
class UFallTowardsSplineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(PlayerMovementTags::CoreMovement);
	default CapabilityTags.Add(PlayerMovementTags::AirMotion);

	default DebugCategory = n"Movement";
	
	default TickGroup = EHazeTickGroup::LastMovement;

	// One before air motion
	default TickGroupOrder = 159;

	UFallTowardsSplineComponent SplineContainer;
	UPlayerMovementComponent MoveComp;
	UPlayerAirMotionSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SplineContainer = UFallTowardsSplineComponent::GetOrCreate(Player);
		Settings = UPlayerAirMotionSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(SplineContainer.Spline == nullptr)
			return false;

		if(SplineContainer.GuideRadius <= 1)
			return false;

		if(MoveComp.IsOnAnyGround())
			return false;

		return true;
	}



	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(SplineContainer.Spline == nullptr)
			return true;

		if(SplineContainer.GuideRadius <= 1)
			return true;

		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// When falling, we use the center location
		const FVector ActorLocation = Player.ActorCenterLocation;

		auto SplinePosition = SplineContainer.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		float AligedAlpha = SplinePosition.WorldForwardVector.DotProductLinear(MoveComp.VerticalVelocity.GetSafeNormal());
		if(AligedAlpha < 0.5)
			return;

		FVector DeltaToSpline = (SplinePosition.WorldLocation - ActorLocation);
		float InnerRadius = SplineContainer.GuideRadius * 0.5;
		float SplineDistanceModifier = Math::Saturate((DeltaToSpline.Size() - InnerRadius) / (SplineContainer.GuideRadius - InnerRadius));
		
		if(SplineDistanceModifier < KINDA_SMALL_NUMBER)
			return;

		float CurrentAlphaToSpline = MoveComp.HorizontalVelocity.GetSafeNormal().DotProduct(DeltaToSpline.GetSafeNormal());
		CurrentAlphaToSpline += 1;
		CurrentAlphaToSpline *= 0.5;
		CurrentAlphaToSpline *= 1 - CurrentAlphaToSpline;

		Player.AddMovementImpulse(-MoveComp.HorizontalVelocity * CurrentAlphaToSpline);

		FVector WantedVelocityToSpline = DeltaToSpline / DeltaTime;
		WantedVelocityToSpline = Math::VInterpTo(FVector::ZeroVector, WantedVelocityToSpline, DeltaTime, SplineDistanceModifier * 2);
		Player.AddMovementImpulse(WantedVelocityToSpline * CurrentAlphaToSpline);
	}

	// void GenerateMovement(float DeltaTime) override
	// {
	// 	Super::GenerateMovement(DeltaTime);

	// 	// When falling, we use the center location
	// 	const FVector ActorLocation = Player.ActorCenterLocation;

	// 	auto SplinePosition = SplineContainer.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
	// 	float AligedAlpha = SplinePosition.WorldForwardVector.DotProductLinear(MoveComp.VerticalVelocity.GetSafeNormal());
	// 	if(AligedAlpha < 0.5)
	// 		return;

	// 	FVector DeltaToSpline = (SplinePosition.WorldLocation - ActorLocation);
	// 	float InnerRadius = SplineContainer.GuideRadius * 0.5;
	// 	float SplineDistanceModifier = Math::Saturate((DeltaToSpline.Size() - InnerRadius) / (SplineContainer.GuideRadius - InnerRadius));
		
	// 	if(SplineDistanceModifier < KINDA_SMALL_NUMBER)
	// 		return;

	// 	float CurrentAlphaToSpline = MoveComp.HorizontalVelocity.GetSafeNormal().DotProduct(DeltaToSpline.GetSafeNormal());
	// 	CurrentAlphaToSpline += 1;
	// 	CurrentAlphaToSpline *= 0.5;
	// 	CurrentAlphaToSpline *= 1 - CurrentAlphaToSpline;

	// 	Movement.AddHorizontalVelocity(-MoveComp.HorizontalVelocity * CurrentAlphaToSpline);

	// 	FVector WantedVelocityToSpline = DeltaToSpline / DeltaTime;
	// 	WantedVelocityToSpline = Math::VInterpTo(FVector::ZeroVector, WantedVelocityToSpline, DeltaTime, SplineDistanceModifier * 2);
	// 	Movement.AddHorizontalVelocity(WantedVelocityToSpline * CurrentAlphaToSpline);
	// }
};