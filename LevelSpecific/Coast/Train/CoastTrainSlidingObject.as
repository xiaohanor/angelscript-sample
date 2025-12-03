class ACoastTrainSlidingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UCoastTrainCartBasedDisableComponent CartDisableComp;
	default CartDisableComp.bActorIsVisualOnly = true;
	default CartDisableComp.bAutoDisable = true;
	default CartDisableComp.AutoDisableRange = 15000.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UCoastTrainSlidingObjectVisualizerComponent VisualizerComp;
#endif
	
	UPROPERTY(EditAnywhere, Category = "Sliding Object")
	float Gravity = 1400.0;
	UPROPERTY(EditAnywhere, Category = "Sliding Object")
	float Friction = 2.0;
	UPROPERTY(EditAnywhere, Category = "Sliding Object")
	float RotationSpeedAfterFallOff = 180.0;
	UPROPERTY(EditAnywhere, Category = "Sliding Object")
	float MinimumSlideAngle = 15.0;
	UPROPERTY(EditAnywhere, Category = "Sliding Object", Meta = (MakeEditWidget))
	FVector ConstraintBoundaryMin(-1000.0, -1000.0, 0.0);
	UPROPERTY(EditAnywhere, Category = "Sliding Object", Meta = (MakeEditWidget))
	FVector ConstraintBoundaryMax(1000.0, 1000.0, 0.0);
	UPROPERTY(EditAnywhere, Category = "Sliding Object", Meta = (MakeEditWidget))
	FVector FallOffBoundaryMin(-200.0, -200.0, -1.0);
	UPROPERTY(EditAnywhere, Category = "Sliding Object", Meta = (MakeEditWidget))
	FVector FallOffBoundaryMax(200.0, 200.0, 1.0);

	FVector RelativeVelocity;
	bool bFallenOff = false;
	float FallenOffTimer = 0.0;
	FVector FallOffRotationAxis;

	default PrimaryActorTick.TickGroup = ETickingGroup::TG_PostPhysics;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ConstraintBoundaryMin += ActorRelativeLocation;
		ConstraintBoundaryMax += ActorRelativeLocation;

		FallOffBoundaryMin += ActorRelativeLocation;
		FallOffBoundaryMax += ActorRelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FTransform ParentTransform;
		FQuat ParentRotation;
		USceneComponent ParentComp = RootComponent.AttachParent;
		if (ParentComp != nullptr)
		{
			ParentTransform = ParentComp.WorldTransform;
			ParentRotation = ParentTransform.Rotation;
		}

		FVector WorldVelocity = ParentRotation.RotateVector(RelativeVelocity);

		if (bFallenOff)
		{
			WorldVelocity += FVector::DownVector * Gravity * DeltaSeconds;

			ActorLocation += WorldVelocity * DeltaSeconds;
			SetActorLocationAndRotation(
				ActorLocation + WorldVelocity * DeltaSeconds,
				FQuat(FallOffRotationAxis, Math::DegreesToRadians(-RotationSpeedAfterFallOff) * DeltaSeconds) * ActorQuat,
			);

			RelativeVelocity = ParentRotation.UnrotateVector(WorldVelocity);

			FallenOffTimer += DeltaSeconds;
			if (FallenOffTimer > 10.0)
				DestroyActor();
		}
		else
		{
			bool bCanSlide = true;
			if (WorldVelocity.Size() <= KINDA_SMALL_NUMBER)
			{
				float CurrentAngle = FVector::UpVector.AngularDistance(ParentRotation.UpVector);
				if (CurrentAngle < Math::DegreesToRadians(MinimumSlideAngle))
					bCanSlide = false;
			}

			if (bCanSlide)
				WorldVelocity += FVector::DownVector.ConstrainToPlane(ParentRotation.UpVector) * Gravity * DeltaSeconds;
			if (WorldVelocity.Size() > KINDA_SMALL_NUMBER)
			{
				WorldVelocity *= Math::Pow(Math::Exp(-Friction), DeltaSeconds);

				FVector DeltaMovement = WorldVelocity * DeltaSeconds;
				FVector WorldLocation = GetActorLocation();
				WorldLocation += DeltaMovement;

				RelativeVelocity = ParentRotation.UnrotateVector(WorldVelocity);

				FVector RelativeLocation = ParentTransform.InverseTransformPosition(WorldLocation);

				if (RelativeLocation.X < ConstraintBoundaryMin.X)
				{
					RelativeLocation.X = ConstraintBoundaryMin.X;
					if (RelativeVelocity.X < 0)
						RelativeVelocity.X = 0.0;
				}
				else if (RelativeLocation.X > ConstraintBoundaryMax.X)
				{
					RelativeLocation.X = ConstraintBoundaryMax.X;
					if (RelativeVelocity.X > 0)
						RelativeVelocity.X = 0.0;
				}

				if (RelativeLocation.Y < ConstraintBoundaryMin.Y)
				{
					RelativeLocation.Y = ConstraintBoundaryMin.Y;
					if (RelativeVelocity.Y < 0)
						RelativeVelocity.Y = 0.0;
				}
				else if (RelativeLocation.Y > ConstraintBoundaryMax.Y)
				{
					RelativeLocation.Y = ConstraintBoundaryMax.Y;
					if (RelativeVelocity.Y > 0)
						RelativeVelocity.Y = 0.0;
				}

				if (RelativeLocation.Z < ConstraintBoundaryMin.Z)
				{
					RelativeLocation.Z = ConstraintBoundaryMin.Z;
					if (RelativeVelocity.Z < 0)
						RelativeVelocity.Z = 0.0;
				}
				else if (RelativeLocation.Z > ConstraintBoundaryMax.Z)
				{
					RelativeLocation.Z = ConstraintBoundaryMax.Z;
					if (RelativeVelocity.Z > 0)
						RelativeVelocity.Z = 0.0;
				}

				SetActorRelativeLocation(RelativeLocation);

				if (RelativeLocation.X < FallOffBoundaryMin.X || RelativeLocation.X > FallOffBoundaryMax.X
				 || RelativeLocation.Y < FallOffBoundaryMin.Y || RelativeLocation.Y > FallOffBoundaryMax.Y
				 || RelativeLocation.Z < FallOffBoundaryMin.Z || RelativeLocation.Z > FallOffBoundaryMax.Z)
				{
					FallOffRotationAxis = WorldVelocity.CrossProduct(ActorUpVector).GetSafeNormal();
					bFallenOff = true;
				}
			}
			else
			{
				RelativeVelocity = FVector::ZeroVector;
			}
		}
	}
};

#if EDITOR
class UCoastTrainSlidingObjectVisualizerComponent : UActorComponent {}
class UCoastTrainSlidingObjectComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCoastTrainSlidingObjectVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Actor = Cast<ACoastTrainSlidingObject>(Component.Owner);
		FTransform Transform = Actor.ActorTransform;

		FBox ConstraintBox;
		ConstraintBox += Actor.ConstraintBoundaryMin;
		ConstraintBox += Actor.ConstraintBoundaryMax;

		FVector ConstraintOrigin = Transform.TransformPosition(ConstraintBox.Center);
		FVector ConstraintExtent = Transform.GetScale3D() * ConstraintBox.Extent;
		DrawWireBox(
			ConstraintOrigin, ConstraintExtent, Transform.Rotation,
			FLinearColor::Red, 10.0
		);

		FBox FallOffBox;
		FallOffBox += Actor.FallOffBoundaryMax;
		FallOffBox += Actor.FallOffBoundaryMin;

		FVector FallOffOrigin = Transform.TransformPosition(FallOffBox.Center);
		FVector FallOffExtent = Transform.GetScale3D() * FallOffBox.Extent;
		DrawWireBox(
			FallOffOrigin, FallOffExtent, Transform.Rotation,
			FLinearColor::Yellow, 10.0
		);
	}
}
#endif