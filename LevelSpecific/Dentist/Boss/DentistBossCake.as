UCLASS(Abstract)
class ADentistBossCake : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent OuterCakeRoot;

	UPROPERTY(DefaultComponent, Attach = OuterCakeRoot)
	USceneComponent InnerCakeRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftHandGrabLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent RightHandGrabLocation;

	UPROPERTY(DefaultComponent, Attach = OuterCakeRoot)
	USceneComponent OuterToothPasteGlobTargetRoot;

	UPROPERTY(DefaultComponent, Attach = InnerCakeRoot)
	USceneComponent InnerToothPasteGlobTargetRoot;

	UPROPERTY(DefaultComponent)
	UHazeMovablePlayerTriggerComponent PlayerOnCakeTrigger;

	UPROPERTY(DefaultComponent)
	UInheritVelocityComponent InheritVelocityComp;

	UPROPERTY(DefaultComponent)
	USquishTriggerBoxComponent SquishTrigger;
	default SquishTrigger.Polarity = ESquishTriggerBoxPolarity::Up;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTemporalLogComp;
#endif

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> ActorsToAttachOuter;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	TArray<AActor> ActorsToAttachNotSpinning;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float OuterTargetRotatingSpeed = 20.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float InnerTargetRotatingSpeed = -50.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float OuterTargetAccelerationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float InnerTargetAccelerationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float OuterTargetDecelerationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float InnerTargetDecelerationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float OuterRadius = 1900.0;

	float OuterRotatingSpeed = 0.0;
	float InnerRotatingSpeed = 0.0;
	bool bRotating = false;
	bool bStopping = false;

	TArray<USceneComponent> NotGlobbedTargets;
	TArray<USceneComponent> GlobbedTargets;

	FVector InitialLocation;

	float SyncedStartRotationTime;
	float SyncedStoppingRotationTime;

	float StoppingStartInnerRotateAmount;
	float StoppingStartOuterRotateAmount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OuterToothPasteGlobTargetRoot.GetChildrenComponents(true, NotGlobbedTargets);
		TArray<USceneComponent> InnerGlobTargets;
		InnerToothPasteGlobTargetRoot.GetChildrenComponents(true, InnerGlobTargets);
		NotGlobbedTargets.Append(InnerGlobTargets);

		InitialLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors, false, false);
		for(auto Actor : AttachedActors)
		{
			if(!ActorsToAttachOuter.Contains(Actor)
			&& !ActorsToAttachNotSpinning.Contains(Actor))
				Actor.DetachFromActor(EDetachmentRule::KeepWorld);
		}

		for(auto Actor : ActorsToAttachOuter)
		{
			if(Actor == nullptr)
				continue;

			if(AttachedActors.Contains(Actor))
				continue;

			Actor.AttachToComponent(OuterCakeRoot, AttachmentRule = EAttachmentRule::KeepWorld);
		}

		for(auto Actor : ActorsToAttachNotSpinning)
		{
			if(Actor == nullptr)
				continue;

			if(AttachedActors.Contains(Actor))
				continue;

			Actor.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bRotating)
		{
			if(bStopping)
			{
				float TimeSinceStopped = Time::GetPredictedGlobalCrumbTrailTime() - SyncedStoppingRotationTime;
				TimeSinceStopped = Math::Max(0.0, TimeSinceStopped);

				float OuterRotatedAmount = Acceleration::GetDistanceAtTimeWithAcceleration(TimeSinceStopped, OuterTargetDecelerationDuration, OuterTargetRotatingSpeed, 0);
				float InnerRotatedAmount = Acceleration::GetDistanceAtTimeWithAcceleration(TimeSinceStopped, InnerTargetDecelerationDuration, InnerTargetRotatingSpeed, 0);

				OuterCakeRoot.SetRelativeRotation(FRotator(0.0, StoppingStartOuterRotateAmount + OuterRotatedAmount, 0.0));
				InnerCakeRoot.SetRelativeRotation(FRotator(0.0, StoppingStartInnerRotateAmount + InnerRotatedAmount, 0.0));

				if(TimeSinceStopped > Math::Max(OuterTargetDecelerationDuration, InnerTargetDecelerationDuration))
				{
					bRotating = false;
					bStopping = false;
				}
			}
			else
			{
				float OuterTimeSinceStart = Time::GetPredictedGlobalCrumbTrailTime() - SyncedStartRotationTime;
				OuterTimeSinceStart = Math::Max(0.0, OuterTimeSinceStart);

				float OuterRotatedAmount = Acceleration::GetDistanceAtTimeWithAcceleration(OuterTimeSinceStart, OuterTargetAccelerationDuration, 0.0, OuterTargetRotatingSpeed);

				OuterCakeRoot.SetRelativeRotation(FRotator(0.0, OuterRotatedAmount, 0.0));

				float InnerTimeSinceStart = OuterTimeSinceStart - 1.0;
				InnerTimeSinceStart = Math::Max(0.0, InnerTimeSinceStart);

				float InnerRotatedAmount = Acceleration::GetDistanceAtTimeWithAcceleration(InnerTimeSinceStart, InnerTargetAccelerationDuration, 0.0, InnerTargetRotatingSpeed);

				InnerCakeRoot.SetRelativeRotation(FRotator(0.0, InnerRotatedAmount, 0.0));
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetStartRotating(float GlobalCrumbTrailTime)
	{
		bRotating = true;
		// OuterSpinTimeLike.Play();

		SyncedStartRotationTime = GlobalCrumbTrailTime;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetStopRotating(float GlobalCrumbTrailTime, float InnerRotatedAmount, float OuterRotatedAmount)
	{
		// OuterSpinTimeLike.Reverse();
		// InnerSpinTimeLike.Reverse();

		bStopping = true;

		SyncedStoppingRotationTime = GlobalCrumbTrailTime;
		StoppingStartInnerRotateAmount = InnerRotatedAmount;
		StoppingStartOuterRotateAmount = OuterRotatedAmount;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		// TArray<USceneComponent> OuterGlobTargets;
		// OuterToothPasteGlobTargetRoot.GetChildrenComponents(true, OuterGlobTargets);
		// for(auto Target : OuterGlobTargets)
		// {
		// 	Debug::DrawDebugSphere(Target.WorldLocation + FVector::UpVector * 5, 200);
		// }

		// TArray<USceneComponent> InnerGlobTargets;
		// InnerToothPasteGlobTargetRoot.GetChildrenComponents(true, InnerGlobTargets);
		// for(auto Target : InnerGlobTargets)
		// {
		// 	Debug::DrawDebugSphere(Target.WorldLocation + FVector::UpVector * 10, 200,12, FLinearColor::Gray);
		// }

		// Debug::DrawDebugCircle(ActorLocation + FVector::UpVector * 5, OuterRadius, 24, FLinearColor::White, 10);
	}
#endif

	FVector GetRightEdge() const
	{
		return ActorLocation + (ActorForwardVector * OuterRadius);
	}

	FVector GetLeftEdge() const
	{
		return ActorLocation - (ActorForwardVector * OuterRadius);
	}

	void ChooseGlobTarget(USceneComponent Target)
	{
		NotGlobbedTargets.RemoveSingleSwap(Target);
		GlobbedTargets.AddUnique(Target);
	}

	void ReturnGlobTarget(USceneComponent Target)
	{
		GlobbedTargets.RemoveSingleSwap(Target);
		NotGlobbedTargets.AddUnique(Target);
	}
};