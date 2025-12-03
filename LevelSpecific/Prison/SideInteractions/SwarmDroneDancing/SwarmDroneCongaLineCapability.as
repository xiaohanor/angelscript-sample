

class USwarmDroneCongaLineCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(SwarmDroneTags::SwarmDroneCongaLineCapability);

	UPlayerSwarmDroneComponent SwarmDroneComponent;
	UPlayerSwarmDroneCongaLineComponent CongaLineComponent;
	UHazeSplineComponent Spline;

	FSplinePosition SplinePosition;

	FHazeAcceleratedFloat AcceleratedSpeed;

	const float TargetSpeed = 100;
	const float DistanceBetweenBots = 30.0;

	const float LineStartDuration = 0.5;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (SwarmDroneComponent != nullptr)
			if (SwarmDroneComponent.bDeswarmifying)
				return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwarmDroneComponent = UPlayerSwarmDroneComponent::Get(Player);
		CongaLineComponent = UPlayerSwarmDroneCongaLineComponent::Get(Player);

		Spline = CongaLineComponent.CongaLine.SplineComponent;
		SplinePosition = Spline.GetSplinePositionAtSplineDistance(Math::RandRange(0, Spline.SplineLength));

		AcceleratedSpeed.SnapTo(0);

		Player.ResetMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration <= LineStartDuration)
		{
			TickLineStart(DeltaTime);
			return;
		}

		AcceleratedSpeed.AccelerateTo(TargetSpeed, 0.2, DeltaTime);
		SplinePosition.Move(AcceleratedSpeed.Value * DeltaTime);

		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];

			FSplinePosition BotSplinePosition = GetTargetTransformForBot(i);

			SwarmBot.SetActorLocation(BotSplinePosition.WorldLocation);

			FQuat Rotation = Math::QInterpTo(SwarmBot.ActorQuat, BotSplinePosition.WorldRotation, DeltaTime, 3);
			SwarmBot.SetActorRotation(Rotation);

			SwarmBot.MovementComponent.ActualVelocity = SwarmBot.ActorForwardVector * AcceleratedSpeed.Value;
		}
	}

	void TickLineStart(float DeltaTime)
	{
		for (int i = 0; i < SwarmDrone::DeployedBotCount; i++)
		{
			ASwarmBot SwarmBot = SwarmDroneComponent.SwarmBots[i];
			
			FSplinePosition TargetPosition = GetTargetTransformForBot(i);

			FVector TargetLocation = TargetPosition.WorldLocation;
			float VerticalOffsetFraction = 1.0 - Math::Saturate(ActiveDuration / (LineStartDuration * 0.5));
			TargetLocation += FVector::UpVector * 100 * VerticalOffsetFraction;

			FVector BotLocation = Math::VInterpConstantTo(SwarmBot.ActorLocation, TargetLocation, DeltaTime, 600);

			FVector MoveDelta = BotLocation - SwarmBot.ActorLocation;
			FQuat Rotation = Math::QInterpTo(SwarmBot.ActorQuat, MoveDelta.ToOrientationQuat(), DeltaTime, 5);

			SwarmBot.SetActorLocation(BotLocation);
			SwarmBot.SetActorRotation(Rotation);
		}
	}

	FSplinePosition GetTargetTransformForBot(int BotId)
	{
		float SplineDistance = SplinePosition.CurrentSplineDistance + DistanceBetweenBots * BotId;

		float SplineWrap = SplineDistance - Spline.SplineLength;
		if (SplineWrap > 0)
			SplineDistance = SplineWrap;

		return Spline.GetSplinePositionAtSplineDistance(SplineDistance);
	}
}