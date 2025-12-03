class AVillageOgre_Follower : AVillageOgreBase
{
	UPROPERTY(EditInstanceOnly)
	AVillageOgreBase ParentOgre;

	UPROPERTY(EditAnywhere)
	float OffsetFromParent = 500.0;

	UPROPERTY(EditAnywhere)
	float SidewaysOffset = 0.0;

	float SplineDist = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		ParentOgre.OnStartedRunning.AddUFunction(this, n"ParentStartedRunning");
	}

	UFUNCTION()
	private void ParentStartedRunning(AVillageOgreBase Ogre)
	{
		FollowSplineComp = ParentOgre.FollowSplineComp;

		bRunning = true;
		bFollowingSpline = true;
		StopSlotAnimation();

		OnStartedRunning.Broadcast(this);
	}

	UFUNCTION(BlueprintOverride, meta = (NoSuperCall))
	void Tick(float DeltaTime)
	{
		if (!bRunning)
			return;

		SplineDist = ParentOgre.SplinePos.CurrentSplineDistance - OffsetFromParent;
		MoveSpeed = ParentOgre.MoveSpeed;
		
		FVector Loc = FollowSplineComp.GetWorldLocationAtSplineDistance(SplineDist);
		FRotator Rot = FollowSplineComp.GetWorldRotationAtSplineDistance(SplineDist).Rotator();

		Loc += Rot.RightVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * SidewaysOffset;
		Loc.Z += ChaseJumpHeightOffset;

		SetActorLocationAndRotation(Loc, Rot);
	}
}