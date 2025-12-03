
class UCoastBomblingSplineMovementCapability : UBasicAIMovementCapability
{	
	default CapabilityTags.Add(n"SplineMovement");	
	default TickGroupOrder = 60;

	USimpleMovementData SimpleMovement;
	ACoastTrainCart TrainCart;
	FTransform PreviousTrainCartTransform;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SimpleMovement = Cast<USimpleMovementData>(Movement);
	}

	UBaseMovementData SetupMovementData() override
	{
		return MoveComp.SetupSimpleMovementData();
	} 

	bool PrepareMove() override
	{
		return MoveComp.PrepareMove(SimpleMovement);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (DestinationComp.FollowSpline == nullptr)
			return false;
		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (DestinationComp.FollowSpline == nullptr)
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		float DistAlongSpline = 0.0;
		DestinationComp.FollowSplinePosition = FSplinePosition(DestinationComp.FollowSpline, DistAlongSpline, DestinationComp.bFollowSplineForwards);

		TrainCart = nullptr;
		auto RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(RespawnComp.Spawner.AttachParentActor);
		else if (Owner.AttachParentActor != nullptr)
			TrainCart = Cast<ACoastTrainCart>(Owner.AttachParentActor);

	    if (Owner.AttachParentActor != nullptr)
		 	Owner.DetachFromActor();

		if (TrainCart != nullptr)	
		{
			PreviousTrainCartTransform = TrainCart.ActorTransform;
			MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);
			MoveComp.FollowComponentMovement(TrainCart.RootComponent, this, Priority = EInstigatePriority::Normal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DestinationComp.FollowSplinePosition = FSplinePosition();
		MoveComp.UnFollowComponentMovement(this);
		MoveComp.ClearFollowEnabledOverride(this);
	}

	void ComposeMovement(float DeltaTime) override
	{	
		// Move exactly along spline, ignoring any impulses and custom velocity
		DestinationComp.FollowSplinePosition.Move(DestinationComp.Speed * DeltaTime);
		FVector SplineLoc = DestinationComp.FollowSplinePosition.WorldLocation;

		if (TrainCart != nullptr)	
		{
			// TODO: Test if this is needed when the follow movement bug is fixed.
			//SplineLoc = TrainCart.ActorTransform.TransformPosition(PreviousTrainCartTransform.InverseTransformPosition(SplineLoc));	
			PreviousTrainCartTransform = TrainCart.ActorTransform;
		}
		Movement.AddDeltaWithCustomVelocity(SplineLoc - Owner.ActorLocation, DestinationComp.FollowSplinePosition.WorldForwardVector * DestinationComp.Speed);

		// Turn towards focus or direction of spline
		if (DestinationComp.Focus.IsValid())
			MoveComp.RotateTowardsDirection(DestinationComp.Focus.GetFocusLocation() - Owner.FocusLocation, MoveSettings.TurnDuration, DeltaTime, Movement);
		else 
			MoveComp.RotateTowardsDirection(DestinationComp.FollowSplinePosition.WorldForwardVector, MoveSettings.TurnDuration, DeltaTime, Movement);
	}
}
