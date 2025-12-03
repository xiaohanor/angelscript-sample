event void FOnHitEnd();

class AMeltdownWorldSpinTreeTrunk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent WeightRoot;

	UPROPERTY(DefaultComponent, Attach = WeightRoot)
	UFauxPhysicsAxisRotateComponent SpinAxis;
	default SpinAxis.LocalRotationAxis = FVector::RightVector;

	UPROPERTY(DefaultComponent, Attach = SpinAxis)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAngle;
	default SyncedAngle.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeMovablePlayerTriggerComponent ZoeTrigger;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeight;

	UPROPERTY()
	FOnHitEnd ReachedEnd;

	FVector Axis;
	float CurrentAngle = 0;
	float Velocity = 0;

	float GravityStrength = 800.0;
	float Friction = 0.1;

	bool bGravityActive = false;
	float RopeLength = 0.0;
	AMeltdownWorldSpinManager Manager;

	float HitEndAngle = -0.2 * PI;
	float MinConstraint = -0.25 * PI;
	float MaxConstraint = 0.155 * PI;
	bool bHitEnd = false;

	bool bIsZoeInTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);
		RopeLength = WeightRoot.RelativeLocation.Size();

		FVector RopeDirection = WeightRoot.RelativeLocation.GetSafeNormal();
		CurrentAngle = Math::DirectionToAngleRadians(FVector2D(-RopeDirection.Z, RopeDirection.X));

		ZoeTrigger.OnPlayerEnter.AddUFunction(this, n"ZoeEnterTrigger");
		ZoeTrigger.OnPlayerLeave.AddUFunction(this, n"ZoeLeaveTrigger");
	}

	UFUNCTION()
	private void ZoeEnterTrigger(AHazePlayerCharacter Player)
	{
		bIsZoeInTrigger = true;
	}

	UFUNCTION()
	private void ZoeLeaveTrigger(AHazePlayerCharacter Player)
	{
		bIsZoeInTrigger = false;
	}

	UFUNCTION(CrumbFunction)
	private void CrumbHitEnd()
	{
		bHitEnd = true;
		ReachedEnd.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void ApplyGravity()
	{
		bGravityActive = true;
	}

	UFUNCTION(BlueprintCallable)
	void DisableGravity()
	{
		bGravityActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Manager == nullptr)
			Manager = AMeltdownWorldSpinManager::GetWorldSpinManager();
		if (Manager == nullptr)
			return;

		if (HasControl())
		{
			const FVector GravityDir = Root.WorldTransform.InverseTransformVector(-Manager.WorldSpinRotation.UpVector);
			const FVector2D PrevRope = Math::AngleRadiansToDirection(CurrentAngle);
			const FVector TangentDir = FVector(PrevRope.Y, 0.0, -PrevRope.X).CrossProduct(FVector::RightVector).GetSafeNormal();

			float Gravity = GravityDir.DotProduct(TangentDir) * GravityStrength;

			CurrentAngle += Velocity/RopeLength * DeltaSeconds;
			if (bGravityActive)
			{
				CurrentAngle += Gravity/RopeLength * Math::Square(DeltaSeconds) * 0.5;
				Velocity += Gravity * DeltaSeconds;
			}

			Velocity *= Math::Pow(Math::Exp(-Friction), DeltaSeconds);
			if (Math::Abs(Velocity) < 0.001)
				Velocity = 0.0;

			if (CurrentAngle < HitEndAngle)
			{
				if (HasControl() && !bHitEnd && bIsZoeInTrigger)
					CrumbHitEnd();
			}

			if (CurrentAngle < MinConstraint)
			{
				if (Velocity < 0.0)
					Velocity *= -0.2;
				CurrentAngle = MinConstraint + Velocity/RopeLength * DeltaSeconds;
			}
			else if (CurrentAngle > MaxConstraint)
			{
				if (Velocity > 0.0)
					Velocity *= -0.2;
				CurrentAngle = MaxConstraint + Velocity/RopeLength * DeltaSeconds;
			}

			SyncedAngle.Value = CurrentAngle;

			// if (bGravityActive)
			// {
			// 	float Offset = 500.0;
			// 	float SpinGravity = 10.0;

			// 	FVector WorldGravityDir = -Manager.WorldSpinRotation.UpVector;
			// 	FVector RotationAxis = SpinAxis.WorldRotationAxis;
			// 	FVector MovementAxis = RotationAxis.CrossProduct(WorldGravityDir).GetSafeNormal();

			// 	FVector LeftOffset = Mesh.WorldTransform.TransformVectorNoScale(FVector(0, Offset, -50));
			// 	float LeftForce = LeftOffset.DotProduct(MovementAxis) * -SpinGravity / Offset;

			// 	FVector RightOffset = Mesh.WorldTransform.TransformVectorNoScale(FVector(0, -Offset, -50));
			// 	float RightForce = RightOffset.DotProduct(MovementAxis) * -SpinGravity / Offset;

			// 	SpinAxis.ApplyAngularForce(LeftForce + RightForce);
			// }
		}

		FVector2D NextRope = Math::AngleRadiansToDirection(SyncedAngle.Value);
		FVector RopeLocation = FVector(NextRope.Y, 0.0, -NextRope.X) * RopeLength;

		WeightRoot.SetRelativeLocationAndRotation(
			RopeLocation,
			FRotator::MakeFromZY(-RopeLocation, FVector::RightVector),
		);
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentSyncedAngle() const 
	{
		return SyncedAngle.Value;
	}
};