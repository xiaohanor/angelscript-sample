UCLASS(Abstract)
class APirateShipHelm : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HelmPivotComp;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent)
    UThreeShotInteractionComponent InteractionComp;

	private bool bIsMounted = false;
	AHazePlayerCharacter MountedPlayer;

	float SteerInput = 0;
	private float WheelVelocity = 0;
	private float WheelValue = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnInteractionStarted.AddUFunction(this, n"OnInteractionStarted");
		InteractionComp.OnInteractionStopped.AddUFunction(this, n"OnInteractionStopped");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsMounted)
		{
			if(Pirate::Helm::bUseStickSpin)
			{
				if(MountedPlayer.IsUsingGamepad())
					WheelVelocity = Math::FInterpConstantTo(WheelVelocity, SteerInput, DeltaSeconds, 10);
				else
					WheelVelocity = Math::FInterpConstantTo(WheelVelocity, SteerInput / 3, DeltaSeconds, 10);
			}
			else
			{
				WheelVelocity = Math::FInterpConstantTo(WheelVelocity, SteerInput, DeltaSeconds, Pirate::Helm::TurnAcceleration);
			}
		}
		else
		{
			WheelVelocity = Math::FInterpConstantTo(WheelVelocity, 0, DeltaSeconds, Pirate::Helm::TurnAcceleration);
		}

		const float TurnSpeed = Pirate::Helm::bUseStickSpin ? Pirate::Helm::StickSpinTurnSpeed : Pirate::Helm::TurnSpeed;

		WheelValue += WheelVelocity * DeltaSeconds * TurnSpeed;

		if(Math::Abs(WheelValue) > 1.0)
		{
			WheelValue = Math::Sign(WheelValue);
			WheelVelocity = 0;
		}

		const float MaxTurnAngle = Pirate::Helm::bUseStickSpin ? Pirate::Helm::StickSpinMaxTurnAngle : Pirate::Helm::MaxTurnAngle;
		HelmPivotComp.SetRelativeRotation(FRotator(0, 0, WheelValue * MaxTurnAngle));
	}

	UFUNCTION()
	private void OnInteractionStarted(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		MountedPlayer = Player;
		bIsMounted = true;
		SteerInput = 0;

		auto PlayerComp = UPirateShipHelmPlayerComponent::Get(Player);
		PlayerComp.Helm = this;
		PlayerComp.bIsMounted = true;
	}

	UFUNCTION()
	private void OnInteractionStopped(UInteractionComponent InteractionComponent, AHazePlayerCharacter Player)
	{
		check(MountedPlayer == Player);
		bIsMounted = false;
		SteerInput = 0;

		auto PlayerComp = UPirateShipHelmPlayerComponent::Get(Player);
		PlayerComp.bIsMounted = false;
	}

	bool IsMounted() const
	{
		return bIsMounted;
	}

	// private float GetAngleToSpline() const
	// {
	// 	const FVector Delta = Pirate::GetSpline().Spline.GetClosestSplineWorldLocationToWorldLocation(ActorLocation) - ActorLocation;
	// 	const FVector DirectionToTarget = Delta.GetSafeNormal();

	// 	const FVector ForwardHorizontal = ActorForwardVector.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
	// 	const FVector DirectionToTargetHorizontal = DirectionToTarget.VectorPlaneProject(FVector::UpVector).GetSafeNormal();
	// 	float Angle = ForwardHorizontal.GetAngleDegreesTo(DirectionToTargetHorizontal);
	// 	Angle = (DirectionToTargetHorizontal.DotProduct(ActorRightVector) > 0) ? Angle : -Angle;

	// 	return Angle;
	// }

	float GetTurnAmount() const
	{
		return WheelValue;

		// if(Pirate::IsWithinSpline(Pirate::GetShip().ActorLocation))
		// {
		// 	return WheelValue;
		// }
		// else
		// {
		// 	const float AngleToSpline = GetAngleToSpline();
		// 	return Math::Clamp(Math::NormalizeToRange(AngleToSpline, -30, 30), -1, 1);
		// }
	}
};