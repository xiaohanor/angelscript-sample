class ACellOnTrack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CableRoot;

	UPROPERTY(DefaultComponent, Attach = CableRoot)
	USceneComponent CellRoot;

	UPROPERTY(DefaultComponent, Attach = CellRoot)
	UStaticMeshComponent CellMesh;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent MovementImpactCallbackComp;

	UPROPERTY(EditInstanceOnly)
	AHazeActor SplineActor;
	UHazeSplineComponent SplineComp;

	UPROPERTY(EditAnywhere)
	bool bMoveAutomatically = true;

	UPROPERTY(EditAnywhere)
	bool bMoveBackAndForth = false;

	UPROPERTY(EditAnywhere)
	float MoveBackAndForthDelay = 2.0;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 1000.0;

	UPROPERTY(EditInstanceOnly)
	bool bPreviewPosition = false;
	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float PreviewFraction = 0.0;

	float OriginalHeight = 0.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor == nullptr)
			return;

		if (bPreviewPosition)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(SplineActor);
			if (Spline == nullptr)
				return;

			FTransform PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * PreviewFraction);
			FRotator Rot = FRotator(PreviewTransform.Rotation);
			Rot.Pitch = Math::Clamp(Rot.Pitch, -8.0, 8.0);
			SetActorLocation(PreviewTransform.Location);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalHeight = CellRoot.RelativeLocation.Z;

		if (SplineActor != nullptr)
		{
			SplineComp = UHazeSplineComponent::Get(SplineActor);
			if (SplineComp != nullptr)
				SplinePos = FSplinePosition(SplineComp, SplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation), true);
		}

		MovementImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"PlayerLanded");
	}

	UFUNCTION()
	private void PlayerLanded(AHazePlayerCharacter Player)
	{
		FVector KnockdownForce;
		FVector KnockdownDirection;
		if (SplinePos.IsForwardOnSpline())
			KnockdownDirection = -SplinePos.WorldForwardVector;
		else
			KnockdownDirection = SplinePos.WorldForwardVector;

		KnockdownForce = (KnockdownDirection * 1600.0) + (FVector::UpVector * 1600.0);
		Player.ApplyKnockdown(KnockdownForce);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bMoveAutomatically)
			return;

		if (SplineComp != nullptr)
		{
			SplinePos.Move(MoveSpeed * DeltaTime);
			SetActorLocation(SplinePos.WorldLocation);
			if (SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength)
			{
				if (bMoveBackAndForth)
				{
					if (SplinePos.IsForwardOnSpline())
					{
						bMoveAutomatically = false;
						SplinePos = FSplinePosition(SplineComp, SplineComp.SplineLength, false);
						Timer::SetTimer(this, n"ResumeMovement", MoveBackAndForthDelay);
					}
				}
				else
					SplinePos = FSplinePosition(SplineComp, 0.0, true);
			}
			else if (SplinePos.CurrentSplineDistance <= 0.0)
			{
				if (bMoveBackAndForth)
				{
					if (!SplinePos.IsForwardOnSpline())
					{
						bMoveAutomatically = false;
						SplinePos = FSplinePosition(SplineComp, 0.0, true);
						Timer::SetTimer(this, n"ResumeMovement", MoveBackAndForthDelay);
					}
				}
			}
		}
	}

	UFUNCTION()
	private void ResumeMovement()
	{
		bMoveAutomatically = true;
	}
}