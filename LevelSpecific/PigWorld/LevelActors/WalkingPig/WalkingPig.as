UCLASS(Abstract)
class AWalkingPig : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PigRoot;

	UPROPERTY(DefaultComponent, Attach = PigRoot)
	UCapsuleComponent CollisionComp;
	default CollisionComp.RemoveTag(ComponentTags::Walkable);

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.0;

	UPROPERTY(EditInstanceOnly)
	ASplineActor FollowSpline;
	UHazeSplineComponent SplineComp;

	FSplinePosition SplinePos;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float StartFraction = 0.0;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 300.0;

	UPROPERTY(EditAnywhere)
	bool bForwards = true;

	UPROPERTY(EditAnywhere)
	bool bAlignWithGround = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (FollowSpline != nullptr)
		{
			SetActorLocationAndRotation(FollowSpline.Spline.GetWorldLocationAtSplineFraction(StartFraction), FollowSpline.Spline.GetWorldRotationAtSplineFraction(StartFraction));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (FollowSpline != nullptr)
			SplinePos = FSplinePosition(FollowSpline.Spline, StartFraction * FollowSpline.Spline.SplineLength, bForwards);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (FollowSpline != nullptr)
		{
			SplinePos.Move(MoveSpeed * DeltaTime);

			FVector Loc = SplinePos.WorldLocation;
			FRotator Rot = SplinePos.WorldRotation.Rotator();
			if (bAlignWithGround)
			{
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				Trace.IgnorePlayers();
				Trace.IgnoreActor(this);
				Trace.UseLine();

				FVector TraceStart = Loc + (FVector::UpVector * 100.0);
				FHitResult Hit = Trace.QueryTraceSingle(TraceStart, TraceStart - FVector::UpVector * 500.0);
				if (Hit.bBlockingHit)
				{
					Loc.Z = Hit.ImpactPoint.Z;
					Rot = FRotator::MakeFromXZ(Rot.ForwardVector, Hit.ImpactNormal);
					Rot.Yaw = SplinePos.WorldRotation.Rotator().Yaw;
					Rot.Roll = 0.0;
				}
			}

			SetActorLocationAndRotation(Loc, Rot);
		}
	}
}