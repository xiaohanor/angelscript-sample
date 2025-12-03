namespace SanctuarySplineRunDevToggles
{
	const FHazeDevToggleCategory SplineRun = FHazeDevToggleCategory(n"SplineRun");
	const FHazeDevToggleBool StopSpline = FHazeDevToggleBool(SplineRun, n"StopSpline");
};

struct FSanctuaryBossSplineRunChildData
{
	FTransform SplineRelativeTransform;
	FSplinePosition SplinePosition;
}

class ASanctuaryBossSplineRun : ASplineActor
{
	default Spline.EditingSettings.bEnableVisualizeRoll = true;
	default Spline.EditingSettings.bEnableVisualizeScale = true;
	default Spline.EditingSettings.VisualizeRoll = 1000.0;
	default Spline.EditingSettings.VisualizeScale = 1000.0;

	TMap<AActor, FSanctuaryBossSplineRunChildData> MovingActors;

	UPROPERTY(EditAnywhere)
	float MinSpeed = 50.0;
	UPROPERTY(EditAnywhere)
	float MaxSpeed = 900.0;
	FHazeAcceleratedFloat AccSpeed;
	UHazeSplineComponent TargetSpline;
	
	UPROPERTY(DefaultComponent)
	USceneComponent FollowSceneComp;
	
	TArray<AActor> AttachedActors;

	float NormalSpeed = 600;
	UPROPERTY(EditAnywhere)
	bool bShouldSpeedUp = true;
	TArray<FInstigator> StopInstigators;

	UPROPERTY(EditInstanceOnly)
	TSubclassOf<ASanctuaryBossSplineRunMovementParent> MovementParentClass;
	ASanctuaryBossSplineRunMovementParent PlayerMovementParent;

	UPROPERTY(EditAnywhere)
	AActor TargetSplineActor;

	AHazePlayerCharacter Mio;
	AHazePlayerCharacter Zoe;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SanctuarySplineRunDevToggles::SplineRun.MakeVisible();
		InitializeAttachedActors();
		AccSpeed.SnapTo(MinSpeed);

		// if (MovementParentClass != nullptr)
		// 	PlayerMovementParent = SpawnActor(MovementParentClass, ActorLocation, ActorRotation, n"SpineRunPlayerMovementParent");

		// for(auto Player : Game::Players)
		// {
		// 	UPlayerMovementComponent::Get(Player).FollowComponentMovement(FollowSceneComp, this, EMovementFollowComponentType::ResolveCollision, EInstigatePriority::Low);
		// }
		Mio = Game::Mio;
		Zoe = Game::Zoe;
		
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		// for(auto Player : Game::Players)
		// {
		// 	if(Player!=nullptr)
		// 		UPlayerMovementComponent::Get(Player).UnFollowComponentMovement(this);
		// }
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bBothDead = Mio.IsPlayerDead() && Zoe.IsPlayerDead();
		if (bBothDead)
			return;

		// Calculate Speed
		{
			float TargetSpeed = NormalSpeed;
			if (SanctuarySplineRunDevToggles::StopSpline.IsEnabled() || StopInstigators.Num() > 0)
				TargetSpeed = 0.0;
			else if (bShouldSpeedUp && TargetSplineActor != nullptr)
				TargetSpeed = GetSpeedByPlayerDiff();
			AccSpeed.AccelerateTo(TargetSpeed, 1.0, DeltaSeconds);
		}

		for (auto& MovingActor : MovingActors)
		{
			float RemainingDistance = 0.0;

			if (!MovingActor.Value.SplinePosition.Move(AccSpeed.Value * DeltaSeconds, RemainingDistance))
				MovingActor.Value.SplinePosition = TargetSpline.GetSplinePositionAtSplineDistance(RemainingDistance);

			FTransform TransformOnSpline = MovingActor.Value.SplineRelativeTransform * MovingActor.Value.SplinePosition.WorldTransformNoScale;
			TransformOnSpline.Location = MovingActor.Value.SplinePosition.WorldTransform.TransformPosition(MovingActor.Value.SplineRelativeTransform.Location);
			MovingActor.Key.ActorTransform = TransformOnSpline;
		}

		if (PlayerMovementParent != nullptr)
		{
			float RemainingDistance = 0.0;
			if (!PlayerMovementParent.SplinePosition.Move(AccSpeed.Value * DeltaSeconds, RemainingDistance))
				PlayerMovementParent.SplinePosition = TargetSpline.GetSplinePositionAtSplineDistance(RemainingDistance);
			FVector NewMovementParentLocation = TargetSpline.GetSplinePositionAtSplineDistance(PlayerMovementParent.SplinePosition.CurrentSplineDistance).WorldLocation;
			// Only move PlayerMovementParent in XY plane
			NewMovementParentLocation.Z = PlayerMovementParent.ActorLocation.Z;
			PlayerMovementParent.SetActorLocation(NewMovementParentLocation);
		}
	}

	float GetSpeedByPlayerDiff() const
	{
		FVector BetweenZoeMio = (Zoe.ActorLocation - Zoe.ActorLocation) * 0.5;
		//Debug singlplayer
		//FVector BetweenZoeMio = (Zoe.ActorLocation) * 0.5;
		BetweenZoeMio += Zoe.ActorLocation;
		if (Zoe.IsPlayerDead())
			BetweenZoeMio = Zoe.ActorLocation;
		if (Zoe.IsPlayerDead())
			BetweenZoeMio = Zoe.ActorLocation;
		float MaxDistance = 11000.0;
		float DistanceAlpha = Math::Clamp((BetweenZoeMio - TargetSplineActor.ActorLocation).Size() / MaxDistance, 0.0, 1.0);
		return Math::EaseOut(MinSpeed, MaxSpeed, 1.0 - DistanceAlpha, 3);
	}

	UFUNCTION()
	void SnapProgression(float Distance)
	{
		for (auto& MovingActor : MovingActors)
		{
			float RemainingDistance = 0.0;

			if (!MovingActor.Value.SplinePosition.Move(Distance, RemainingDistance))
				MovingActor.Value.SplinePosition = TargetSpline.GetSplinePositionAtSplineDistance(RemainingDistance);

			FTransform TransformOnSpline = MovingActor.Value.SplineRelativeTransform * MovingActor.Value.SplinePosition.WorldTransformNoScale;
			TransformOnSpline.Location = MovingActor.Value.SplinePosition.WorldTransform.TransformPosition(MovingActor.Value.SplineRelativeTransform.Location);
			MovingActor.Key.ActorTransform = TransformOnSpline;
		}
	}

	void InitializeAttachedActors()
	{
		if (TargetSplineActor != nullptr)
			TargetSpline = Spline::GetGameplaySpline(TargetSplineActor);

		if (TargetSpline == nullptr)
			TargetSpline = Spline;

		GetAttachedActors(AttachedActors);

		TArray<AActor> AllChildren;
		for (auto AttachedActor : AttachedActors)
		{
			FSanctuaryBossSplineRunChildData MovingActorData;
			MovingActorData.SplinePosition = Spline.GetClosestSplinePositionToWorldLocation(AttachedActor.ActorLocation);
			MovingActorData.SplineRelativeTransform = AttachedActor.ActorTransform.GetRelativeTransform(MovingActorData.SplinePosition.WorldTransformNoScale);

			if (TargetSplineActor != nullptr)
				MovingActorData.SplinePosition = TargetSpline.GetSplinePositionAtSplineDistance(MovingActorData.SplinePosition.CurrentSplineDistance);

			MovingActors.Add(AttachedActor, MovingActorData);

			AttachedActor.GetAttachedActors(AllChildren, true, true);
			for (auto GrandChild : AllChildren)
			{
				USanctuaryBossStopSplineRunComponent SplineStopper = USanctuaryBossStopSplineRunComponent::Get(GrandChild);
				if (SplineStopper != nullptr)
					SplineStopper.AssignSplineRun(this, AttachedActor);
			}

			//Added cuz darkportal was acting weird when dragging blocks in the splinerun
			AttachedActor.DetachFromActor();
		}
	}
};