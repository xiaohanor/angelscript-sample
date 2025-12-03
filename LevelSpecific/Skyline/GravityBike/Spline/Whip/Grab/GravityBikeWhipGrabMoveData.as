struct FGravityBikeWhipGrabMoveData
{
	private UGravityBikeWhipComponent WhipComp;
	private FHazeAcceleratedVector AccRelativeLocation;
	private FHazeAcceleratedFloat AccAngleOffset;
	private FHazeAcceleratedFloat AccDistanceOffset;
	private EGravityBikeWhipState CurrentState;
	private bool bIsLockedToWhipTransform = false;

	FGravityBikeWhipGrabMoveData(UGravityBikeWhipComponent InWhipComp, FVector WorldLocation, FVector WorldVelocity)
	{
		WhipComp = InWhipComp;
		CurrentState = WhipComp.GetWhipState();

		switch(WhipComp.GetWhipState())
		{
			case EGravityBikeWhipState::Lasso:
				CurrentState = EGravityBikeWhipState::Pull;
				break;

			default:
				CurrentState = WhipComp.GetWhipState();
		}

		FTransform ReferenceTransform = WhipComp.GetWhipReferenceTransform();
		FVector RelativeLocation = ReferenceTransform.InverseTransformPositionNoScale(WorldLocation);
		FVector RelativeVelocity = ReferenceTransform.InverseTransformVectorNoScale(WorldVelocity);
		AccRelativeLocation.SnapTo(RelativeLocation, RelativeVelocity);
	}

	EGravityBikeWhipState GetCurrentWhipState() const
	{
		return CurrentState;
	}

	void SetIsLockedToWhipTransform(bool bLockToWhipTransform)
	{
		if(bIsLockedToWhipTransform == bLockToWhipTransform)
			return;

		if(bLockToWhipTransform)
		{
			FVector WorldLocation = WhipComp.GetWhipReferenceTransform().TransformPositionNoScale(AccRelativeLocation.Value);
			FVector NewRelativeLocation = WhipComp.GetWhipImmediateTransform().InverseTransformPositionNoScale(WorldLocation);

			FVector WorldVelocity = WhipComp.GetWhipReferenceTransform().TransformVectorNoScale(AccRelativeLocation.Velocity);
			FVector NewRelativeVelocity = WhipComp.GetWhipImmediateTransform().InverseTransformVectorNoScale(WorldVelocity);

			AccRelativeLocation.SnapTo(NewRelativeLocation, NewRelativeVelocity);
		}
		else
		{
			FVector WorldLocation = WhipComp.GetWhipImmediateTransform().TransformPositionNoScale(AccRelativeLocation.Value);
			FVector NewRelativeLocation = WhipComp.GetWhipReferenceTransform().InverseTransformPositionNoScale(WorldLocation);

			FVector WorldVelocity = WhipComp.GetWhipImmediateTransform().TransformVectorNoScale(AccRelativeLocation.Velocity);
			FVector NewRelativeVelocity = WhipComp.GetWhipReferenceTransform().InverseTransformVectorNoScale(WorldVelocity);

			AccRelativeLocation.SnapTo(NewRelativeLocation, NewRelativeVelocity);
		}

		bIsLockedToWhipTransform = bLockToWhipTransform;
	}

	void Tick(int GrabbedIndex, float ActiveDuration, float DeltaTime, EGravityBikeWhipState DesiredState)
	{
		switch(DesiredState)
		{
			case EGravityBikeWhipState::None:
				return;

			case EGravityBikeWhipState::StartGrab:
			{
				SetIsLockedToWhipTransform(false);
				CurrentState = DesiredState;
				TickStartGrab(DeltaTime);
				break;
			}

			case EGravityBikeWhipState::Pull:
			{
				SetIsLockedToWhipTransform(false);
				CurrentState = DesiredState;
				TickPull(DeltaTime);
				break;
			}

			case EGravityBikeWhipState::Lasso:
			{
				if(CurrentState == EGravityBikeWhipState::Pull)
				{
					TickPull(DeltaTime);

					const FVector TargetRelativeLocation = GetWhipTargetRelativeToReference();
					if(AccRelativeLocation.Value.Equals(TargetRelativeLocation, 50))
						CurrentState = EGravityBikeWhipState::Lasso;
				}
				else
				{
					SetIsLockedToWhipTransform(!WhipComp.IsMultiGrab());
					CurrentState = DesiredState;
					TickLasso(DeltaTime);
				}
				break;
			}

			case EGravityBikeWhipState::ThrowRebound:
			{
				SetIsLockedToWhipTransform(false);
				CurrentState = DesiredState;
				TickThrowRebound(ActiveDuration, DeltaTime);
				break;
			}

			case EGravityBikeWhipState::Throw:
			{
				SetIsLockedToWhipTransform(false);
				CurrentState = DesiredState;
				TickThrow(DeltaTime);
				break;
			}
		}

		if(WhipComp.IsMultiGrab())
		{
			float Alpha = GrabbedIndex / float(WhipComp.GetGrabbedCount());
			float RadianOffset = Alpha * TWO_PI;
			AccAngleOffset.AccelerateTo(RadianOffset, GravityBikeWhip::MultiGrabOffsetAccelerationDuration, DeltaTime);
			AccDistanceOffset.AccelerateTo(GravityBikeWhip::MultiGrabDistance, GravityBikeWhip::MultiGrabOffsetAccelerationDuration, DeltaTime);
		}
		else
		{
			AccAngleOffset.AccelerateTo(0, GravityBikeWhip::MultiGrabOffsetAccelerationDuration, DeltaTime);
			AccDistanceOffset.AccelerateTo(0, GravityBikeWhip::MultiGrabOffsetAccelerationDuration, DeltaTime);
		}
	}

	private void TickStartGrab(float DeltaTime)
	{
		// Inherit velocity from last frame
		FVector Velocity = AccRelativeLocation.Velocity;

		// Slow down slightly
		Velocity = Math::VInterpConstantTo(Velocity, FVector::ZeroVector, DeltaTime, GravityBikeWhip::StartGrabDecelerateSpeed);

		// Keep moving in velocity direction
		AccRelativeLocation.Value += Velocity * DeltaTime;
		AccRelativeLocation.Velocity = Velocity;

		DebugPrint("StartGrab");
	}

	private void TickPull(float DeltaTime)
	{
		// Accelerate towards whip target

		Accelerate(GravityBikeWhip::PullAccelerateDuration, DeltaTime);

		DebugPrint("Pull");
	}

	private void TickLasso(float DeltaTime)
	{
		// Stay with whip target
		Accelerate(GravityBikeWhip::LassoAccelerateDuration, DeltaTime);

		DebugPrint("Lasso");
	}

	private void TickThrowRebound(float ActiveDuration, float DeltaTime)
	{
		// Stay with whip target
		float Duration = GravityBikeWhip::ThrowAccelerateDuration;
		const float Alpha = ActiveDuration / WhipComp.FeatureData.GetReboundDuration();
		const float Multiplier = WhipComp.FeatureData.WhipAccelerationDurationMultiplier.GetFloatValue(Alpha);
		Duration *= Multiplier;
		Accelerate(Duration, DeltaTime);

		DebugPrint("Throw Rebound");
	}

	private void TickThrow(float DeltaTime)
	{
		// Stay with whip target
		Accelerate(GravityBikeWhip::ThrowAccelerateDuration, DeltaTime);

		DebugPrint("Throw");
	}

	void Accelerate(float Duration, float DeltaTime)
	{
		if(bIsLockedToWhipTransform)
		{
			AccRelativeLocation.AccelerateTo(FVector::ZeroVector, Duration, DeltaTime);
		}
		else
		{
			const FVector TargetRelativeLocation = GetWhipTargetRelativeToReference();
			AccRelativeLocation.AccelerateTo(TargetRelativeLocation, Duration, DeltaTime);
		}
	}

	FVector GetWhipTargetRelativeToReference() const
	{
		FVector TargetWorldLocation = WhipComp.GetWhipImmediateLocation();
		return WhipComp.GetWhipReferenceTransform().InverseTransformPositionNoScale(TargetWorldLocation);
	}

	FVector GetWorldLocation() const
	{
		const FTransform WhipTransform = WhipComp.GetWhipImmediateTransform();
		const FTransform ReferenceTransform = WhipComp.GetWhipReferenceTransform();
		const FQuat OffsetRotation = ReferenceTransform.Rotation * FQuat(FVector::ForwardVector, AccAngleOffset.Value + Time::GameTimeSeconds * GravityBikeWhip::MultiGrabSpinSpeed);
		const FVector Offset = OffsetRotation.UpVector * AccDistanceOffset.Value;

		if(bIsLockedToWhipTransform)
		{
			FVector WorldLocation = WhipTransform.TransformPositionNoScale(AccRelativeLocation.Value);
			return WorldLocation + Offset;
		}
		else
		{
			FVector WorldLocation =  ReferenceTransform.TransformPositionNoScale(AccRelativeLocation.Value);
			return WorldLocation + Offset;
		}
	}

	FVector GetRelativeVelocity() const
	{
		return AccRelativeLocation.Velocity;
	}

	void DebugPrint(FString String) const
	{
		if (GravityBikeWhip::bDrawWhipState)
			Debug::DrawDebugString(GetWorldLocation(), String, FLinearColor::Red, 0, 2);
	}
};