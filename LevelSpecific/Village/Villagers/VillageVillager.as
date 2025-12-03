event void FVillageVillagerEvent();

UCLASS(Abstract)
class AVillageVillager : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeCapsuleCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent)
	URagdollComponent RagdollComp;

	UPROPERTY()
	FVillageVillagerEvent OnStartedRunning;

	UPROPERTY()
	FVillageVillagerEvent OnReachedEndOfSpline;

	UPROPERTY()
	FVillageVillagerEvent OnKilled;

	UPROPERTY(EditInstanceOnly, Category = "Spline")
	AActor FollowSplineActor;
	UHazeSplineComponent FollowSplineComp;

	UPROPERTY(EditAnywhere)
	bool bInterpMovement = false;

	bool bKilled = false;

	UPROPERTY(EditAnywhere)
	float MoveSpeed = 600.0;
	bool bRunning = false;

	FSplinePosition SplinePos;

	UFUNCTION()
	void Kill()
	{
		if (bKilled)
			return;
		
		bKilled = true;
		BP_Kill();

		OnKilled.Broadcast();

		AddActorDisable(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Kill() {}

	UFUNCTION()
	void Ragdoll()
	{
		RagdollComp.bAllowRagdoll.Apply(true, this);
		RagdollComp.ApplyRagdoll(SkelMeshComp, CollisionComp);
	}

	UFUNCTION()
	void StartRunning(ASplineActor Spline = nullptr)
	{
		if (bRunning)
			return;

		if (Spline != nullptr)
			FollowSplineActor = Spline;

		FollowSplineComp = UHazeSplineComponent::Get(FollowSplineActor);

		float SplineDist = FollowSplineComp.GetClosestSplineDistanceToWorldLocation(ActorLocation);
		SplinePos = FSplinePosition(FollowSplineComp, SplineDist, true);

		bRunning = true;
		SetActorTickEnabled(true);

		OnStartedRunning.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bRunning)
		{
			SplinePos.Move(MoveSpeed * DeltaTime);

			FVector Loc;
			FRotator Rot;
			if (bInterpMovement)
			{
				Loc = Math::VInterpTo(ActorLocation, SplinePos.WorldLocation, DeltaTime, 2.0);
				Rot = Math::RInterpTo(ActorRotation, SplinePos.WorldRotation.Rotator(), DeltaTime, 2.0);
			}
			else
			{
				Loc = SplinePos.WorldLocation;
				Rot = SplinePos.WorldRotation.Rotator();
			}

			SetActorLocationAndRotation(Loc, Rot);

			if ((SplinePos.CurrentSplineDistance >= SplinePos.CurrentSpline.SplineLength && Loc.Equals(SplinePos.WorldLocation, 20.0)) || (SplinePos.CurrentSplineDistance <= 0.0 && !SplinePos.IsForwardOnSpline()))
			{
				MoveSpeed = 0.0;
				bRunning = false;
				OnReachedEndOfSpline.Broadcast();
			}
		}
	}
}