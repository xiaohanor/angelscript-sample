class AVillageFlyingBoat : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoatRoot;

	UPROPERTY(DefaultComponent, Attach = BoatRoot)
	USceneComponent HoverRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent FrontRightWingRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent FrontLeftWingRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent BackRightWingRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent BackLeftWingRoot;

	UPROPERTY(DefaultComponent, Attach = HoverRoot)
	USceneComponent BackWingRoot;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSplineActor;
	UHazeSplineComponent FollowSplineComp;

	UPROPERTY(EditAnywhere)
	bool bFollowingSpline = true;

	UPROPERTY(EditInstanceOnly, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StartFraction = 0.0;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 800.0;

	UPROPERTY(EditAnywhere)
	bool bForwardsOnSpline = true;

	UPROPERTY(EditAnywhere)
	bool bResetOnEnd = false;

	FSplinePosition SplinePos;

	float HoverTimeOffset = 0.0;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (FollowSplineActor != nullptr)
		{
			UHazeSplineComponent Spline = UHazeSplineComponent::Get(FollowSplineActor);
			FTransform PreviewTransform;

			PreviewTransform = Spline.GetWorldTransformAtSplineDistance(Spline.SplineLength * StartFraction);

			SetActorLocationAndRotation(PreviewTransform.Location, PreviewTransform.Rotation);
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (FollowSplineActor != nullptr)
		{
			FollowSplineComp = FollowSplineActor.Spline;
			SplinePos = FSplinePosition(FollowSplineComp, FollowSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation), bForwardsOnSpline);

			SetActorLocation(FollowSplineComp.GetWorldLocationAtSplineFraction(StartFraction));
		}
	}

	UFUNCTION()
	void StartFollowingSpline()
	{
		if (FollowSplineActor != nullptr)
		{
			FollowSplineComp = FollowSplineActor.Spline;

			SetActorLocation(FollowSplineComp.GetWorldLocationAtSplineFraction(StartFraction));
			bFollowingSpline = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (FollowSplineComp != nullptr && bFollowingSpline)
		{
			SplinePos.Move(MoveSpeed * DeltaTime);
			SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);
			if (bResetOnEnd && SplinePos.IsAtStartOrEnd())
			{
				float Dist = bForwardsOnSpline ? 0.0 : FollowSplineComp.SplineLength;
				SplinePos = FSplinePosition(FollowSplineComp, Dist, bForwardsOnSpline);
			}
		}

		float Time = Time::GameTimeSeconds + HoverTimeOffset;
		float FrontWingPitch = Math::Sin(Time * 1.0) * 15.0;
		float BackWingPitch = Math::Sin(Time * 1.5) * 18.0;
		float RearWingYaw = Math::Sin(Time * 1.25) * 10.0;

		FrontLeftWingRoot.SetRelativeRotation(FRotator(FrontWingPitch, 0.0, 0.0));
		FrontRightWingRoot.SetRelativeRotation(FRotator(-FrontWingPitch, 0.0, 0.0));

		BackLeftWingRoot.SetRelativeRotation(FRotator(BackWingPitch, 0.0, 0.0));
		BackRightWingRoot.SetRelativeRotation(FRotator(-BackWingPitch, 0.0, 0.0));

		BackWingRoot.SetRelativeRotation(FRotator(0.0, RearWingYaw, 0.0));
	}
}