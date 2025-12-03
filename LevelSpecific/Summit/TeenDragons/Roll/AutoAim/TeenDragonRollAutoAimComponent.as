class UTeenDragonRollAutoAimComponent : UTargetableComponent
{
	default TargetableCategory = n"PrimaryLevelAbility";
	default UsableByPlayers = EHazeSelectPlayer::Zoe;

	// Range from player under which the targetable is disregarded
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxRange = 2000;

	// Maximum degrees allowed between the look direction and the targetable
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxDegreesAllowed = 50;

	// Rotation Speed towards auto aim component
	UPROPERTY(EditAnywhere, Category = "Settings")
	float InterpSpeed = 4;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bStartDisabled = false;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledInstigator = n"StartDisabled";

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bAllowHoming = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bAllowHoming"))
	bool bAllowHomingCameraRotation = true;

	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (EditCondition = "bAllowHoming"))
	bool bHomingRequireJump = true;

	/**
	 * If the angle from the auto-aim components forward vector to the aim origin is more than a specific angle, then this component is invalid.
	 */
    UPROPERTY(EditAnywhere, Category = "Settings|Forward Angle")
    bool bOnlyValidIfAimOriginIsWithinAngle = false;

	/**
	 * The angle of the aim "cone". If the angle from the auto-aim components forward vector to the aim origin is more than this angle, then this component is invalid.
	 * Specified in degrees. 
	 */
    UPROPERTY(EditAnywhere, Category = "Settings|Forward Angle", Meta = (EditCondition = "bOnlyValidIfAimOriginIsWithinAngle", ClampMin="1.0", ClampMax="179.0"))
    float MaxAimAngle = 90.0;

	bool bAlwaysUse = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(bStartDisabled)
			Disable(StartDisabledInstigator);
	}

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		if(Query.Player == nullptr)
			return false;

		if (bAlwaysUse)
		{
			Query.Result.bPossibleTarget = true;
			Query.Result.Score = BIG_NUMBER;
			return true;
		}

		Targetable::ApplyTargetableRange(Query, MaxRange);

		FVector MoveInput = Query.PlayerMovementInput;

		auto RollComp = UTeenDragonRollComponent::Get(Query.Player);
		FVector CompareVector;
		if(RollComp.ShouldStartHoming(bHomingRequireJump) && !SceneView::IsFullScreen())	
			CompareVector = Query.AimRay.Direction.ConstrainToPlane(Query.PlayerWorldUp).GetSafeNormal();
		else if(MoveInput.IsNearlyZero())
			CompareVector = Query.Player.ActorForwardVector.ConstrainToPlane(Query.PlayerWorldUp).GetSafeNormal();
		else
			CompareVector = Query.PlayerMovementInput;

		if(bOnlyValidIfAimOriginIsWithinAngle)
		{
			// If the aim origin is outside of an aiming cone, then this target is invalid
			float Angle = ForwardVector.GetAngleDegreesTo(-CompareVector);
			if(Angle > MaxAimAngle)
				return false;
		}
		
		// Targetable::ApplyDistanceToScore(Query);
		FVector DirToPoint = (Query.Component.WorldLocation - Query.Player.ActorLocation).GetSafeNormal().ConstrainToPlane(FVector::UpVector);
		float AngleDist = CompareVector.AngularDistance(DirToPoint);
		if(Math::RadiansToDegrees(AngleDist) > MaxDegreesAllowed)
			return false;
		
		float AngleScore = 1.0 / Math::Max(AngleDist, 0.001);
		float DistScore = 1.0 / Query.DistanceToTargetable * 1.0;
		Query.Result.Score = AngleScore + DistScore;
		return true;
	}
}

#if EDITOR
class UTeenDragonRollAutoAimComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTeenDragonRollAutoAimComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UTeenDragonRollAutoAimComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;

		if(Comp.bOnlyValidIfAimOriginIsWithinAngle)
			VisualizeCone(Comp.WorldLocation, Comp.ForwardVector, Comp.MaxAimAngle, Comp.MaxRange);
	}

	void VisualizeCone(FVector Origin, FVector Direction, float ConeAngle, float Radius)
	{
		float ConeRadians = Math::DegreesToRadians(ConeAngle);

		// Construct perpendicular vector
		FVector P1 = Direction.CrossProduct(Direction.GetAbs().Equals(FVector::UpVector) ? FVector::RightVector : FVector::UpVector);
		P1.Normalize();

		FVector P2 = P1.CrossProduct(Direction);

		// Draw cone sides
		FVector Tip = Direction * Radius;
		FVector TiltedTip = FQuat(P1, ConeRadians) * Tip;
		FVector ConeBase = Direction * Math::Cos(ConeRadians) * Radius;

		float StepRadians = TWO_PI / 10;

		for(int i = 0; i < 10; ++i)
		{
			float Angle = i * StepRadians;
			FVector StepTip = FQuat(Direction, Angle) * TiltedTip;

			DrawDashedLine(Origin, Origin + StepTip, FLinearColor::Gray,10, 10);
		}

		// Draw tip circle
		DrawCircle(Origin + ConeBase, Math::Sin(ConeRadians) * Radius, FLinearColor::Yellow, 20.0, Direction);

		// Draw rotational arcs
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 20.0, P1, bDrawSides = false);
		DrawArc(Origin, ConeAngle * 2.0, Radius, Direction, FLinearColor::Yellow, 20.0, P2, bDrawSides = false);
	}
}
#endif