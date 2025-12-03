struct FStaticWorldAxisBounds
{
	FVector NegativeBound;
	FVector PositiveBound;
}

event void FOnHijackStarted();
event void FOnHijackStopped();

class ASwarmDroneSimpleMovementHijackable : ASwarmDroneHijackable
{
	default CapabilityComponent.InitialStoppedSheets.Add(SwarmDroneMovementHijackSheets::SimpleMovement);
	UPROPERTY()
	FOnHijackStarted OnHijackStarted;
	UPROPERTY()
	FOnHijackStopped OnHijackStopped;

	UPROPERTY(EditAnywhere)
	FSwarmDroneSimpleMovementHijackSettings MovementSettings;

	FStaticWorldAxisBounds StaticWorldAxisBounds;

	FVector Velocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (MovementSettings.HijackType == ESwarmDroneSimpleMovementHijackType::AxisConstrained)
			MovementSettings.AxisConstrainedSettings.GetWorldBounds(RootComponent, StaticWorldAxisBounds.NegativeBound, StaticWorldAxisBounds.PositiveBound);
	}

	void OnHijackStart(FSwarmDroneHijackParams HijackParams) override
	{
		Super::OnHijackStart(HijackParams);
		StartCapabilitySheet(SwarmDroneMovementHijackSheets::SimpleMovement, this);
		OnHijackStarted.Broadcast();
	}

	void OnHijackStop() override
	{
		Super::OnHijackStop();
		StopCapabilitySheet(SwarmDroneMovementHijackSheets::SimpleMovement, this);
		OnHijackStopped.Broadcast();
	}

	FVector GetWorldAxisConstraint() const
	{
		FVector AxisConstraint = MovementSettings.AxisConstrainedSettings.GetConstraintVector();
		return ActorTransform.TransformVector(AxisConstraint).GetSafeNormal();
	}
}