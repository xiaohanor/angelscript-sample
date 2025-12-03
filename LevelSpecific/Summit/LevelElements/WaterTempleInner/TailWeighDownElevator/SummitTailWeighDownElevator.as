class ASummitTailWeighDownElevator : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MoveRoot;

	UPROPERTY(DefaultComponent, Attach = MoveRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	USummitWorldFeedbackComponent FeedbackComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector MoveDirection = FVector::UpVector;
	 
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveAmount = 400.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerLandOnImpulse = 25.0;

	UPROPERTY(EditAnywhere, Category = "Setup")
	ASummitTailWeighDownElevatorWeight Weight;

	FVector StartLocation;
	FVector EndLocation;

	FVector MeshStartRelativeLocation;

	FHazeAcceleratedVector AccMeshLocation;

	bool bIsMoving = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = MoveRoot.RelativeLocation;
		EndLocation = StartLocation + MoveDirection * MoveAmount;

		MeshStartRelativeLocation = MeshRoot.RelativeLocation;
		AccMeshLocation.SnapTo(MeshStartRelativeLocation);

		if(Weight != nullptr)
		{
			Weight.TranslateComp.OnConstraintHit.AddUFunction(this, n"WeightConstraintHit");
			AddTickPrerequisiteActor(Weight);
		}

		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpactedByPlayer");
	}

	UFUNCTION()
	private void OnGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		AccMeshLocation.Velocity += FVector::DownVector * PlayerLandOnImpulse;
	}

	UFUNCTION()
	private void OnGroundLeftByPlayer(AHazePlayerCharacter Player)
	{
	}

	const float WeightConstraintSpeedForMaxHit = 240.0;
	UFUNCTION()
	private void WeightConstraintHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		FSummitTailWeighDownElevatorConstraintHitParams Params;
		Params.HitStrength = Math::GetPercentageBetweenClamped(0, WeightConstraintSpeedForMaxHit, HitStrength);
		if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Min)
			USummitTailWeighDownElevatorEventHandler::Trigger_OnHitConstraintTop(this, Params);
		else if(Edge == EFauxPhysicsTranslateConstraintEdge::AxisZ_Max)
			USummitTailWeighDownElevatorEventHandler::Trigger_OnHitConstraintBottom(this, Params);

		FeedbackComp.PlayOneShotFeedbackForBoth();
	}

	const float MinSpeedToBeCountedAsMoving = 10.0;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccMeshLocation.SpringTo(MeshStartRelativeLocation, 40, 0.8, DeltaSeconds);
		MeshRoot.RelativeLocation = AccMeshLocation.Value;

		if(Weight == nullptr)
			return;
		
		float WeightSpeed = Weight.TranslateComp.GetVelocity().Size(); 
		if(!bIsMoving)
		{
			if(!Math::IsNearlyZero(WeightSpeed, MinSpeedToBeCountedAsMoving))
			{
				USummitTailWeighDownElevatorEventHandler::Trigger_OnStartedMoving(this);
				bIsMoving = true;
			}
		}
		else
		{
			if(Math::IsNearlyZero(WeightSpeed, MinSpeedToBeCountedAsMoving))
			{
				USummitTailWeighDownElevatorEventHandler::Trigger_OnStoppedMoving(this);
				bIsMoving = false;
			}
		}

		MoveRoot.RelativeLocation = Math::Lerp(StartLocation, EndLocation, 1 - Weight.WeighedDownAlpha);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FBox LocalBounds = PlatformMesh.ComponentLocalBoundingBox;
		FVector BoxExtent = LocalBounds.Extent;

		FVector MoveOffset = ActorTransform.TransformVectorNoScale(MoveDirection * MoveAmount);
		FVector DrawLocation = ActorLocation + MoveOffset;
		Debug::DrawDebugSolidBox(DrawLocation, BoxExtent * PlatformMesh.WorldScale, PlatformMesh.WorldRotation, FLinearColor(1.00, 0.00, 0.00));
		Debug::DrawDebugString(DrawLocation, "Fully Moved Location", FLinearColor::Red);
	}
#endif
};