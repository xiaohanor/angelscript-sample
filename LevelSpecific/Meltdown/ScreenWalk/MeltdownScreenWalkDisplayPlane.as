UCLASS(Abstract)
class AMeltdownScreenWalkDisplayPlane : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent Pivot;

	FHazeAcceleratedQuat CurrentRotation;
	bool bWasOnGround = false;
	
	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Ripple(FVector Location)
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Suck(FVector Location, bool bEnabled)
	{
		
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void Deguass()
	{
		
	}

	UFUNCTION(BlueprintEvent)
	void StartPlaneTransition(float FadeTime)
	{}

	UFUNCTION(DevFunction)
	void Stomp()
	{
		FVector Axis;
		float Angle = 0;
		CurrentRotation.Value.ToAxisAndAngle(Axis, Angle);
		CurrentRotation.VelocityAxisAngle = Axis * Angle * 5.0;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector RelativePos = ActorTransform.InverseTransformPosition(Game::Zoe.ActorLocation) / 50.0;

		UPlayerMovementComponent MoveComp = UPlayerMovementComponent::Get(Game::Zoe);
		if (MoveComp.IsOnAnyGround())
		{
			FRotator WantedRotation;
			WantedRotation.Pitch = Math::GetMappedRangeValueClamped(
				FVector2D(-1.0, 1.0),
				FVector2D(5.0, -5.0),
				RelativePos.Z
			);
			WantedRotation.Yaw = Math::GetMappedRangeValueClamped(
				FVector2D(-1.0, 1.0),
				FVector2D(5.0, -5.0),
				RelativePos.Y
			);

			CurrentRotation.AccelerateTo(WantedRotation.Quaternion(), 1.0, DeltaSeconds);
			bWasOnGround = true;
		}
		else
		{
			if (bWasOnGround)
			{
				bWasOnGround = false;

				FVector Axis;
				float Angle = 0;
				CurrentRotation.Value.ToAxisAndAngle(Axis, Angle);
				CurrentRotation.VelocityAxisAngle = Axis * Angle * 1.5;
			}

			CurrentRotation.SpringTo(FQuat::Identity, 4.0, 0.5, DeltaSeconds);
		}

		Pivot.RelativeRotation = CurrentRotation.Value.Rotator();
	}
};
