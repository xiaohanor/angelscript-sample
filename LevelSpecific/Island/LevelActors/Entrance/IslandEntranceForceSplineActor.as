class UIslandEntranceSplineForceResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);

	const AIslandEntranceForceSplineActor ForceComp;

	UBaseMovementResolver Resolver;

	FVector ForceDirection;
	float ForceStrength;

	bool SupportsResolver(const UBaseMovementResolver InResolver) const override
	{
		if(!InResolver.Owner.IsA(AHazePlayerCharacter))
			return false;

		return Super::SupportsResolver(InResolver);
	}

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UIslandEntranceSplineForceResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		ForceDirection = Other.ForceDirection;
		ForceStrength = Other.ForceStrength;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);

		Resolver = InResolver;

		auto ForceResolverComp = UIslandEntranceSplineForceResolverExtensionComponent::Get(InResolver.Owner);
		ForceComp = ForceResolverComp.ForceSpline;

		auto OwningPlayer = Cast<AHazePlayerCharacter>(Resolver.Owner);
		ForceDirection = ForceComp.GetDirectionForPlayer(OwningPlayer);
		ForceStrength = ForceComp.GetForceStrengthForPlayer(OwningPlayer);
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		if(!bFirstIteration)
			return true;

		FVector ForceVelocity = ForceDirection * ForceStrength;

		FMovementDelta OriginalDelta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
		OriginalDelta = FMovementDelta(OriginalDelta.Delta + ForceVelocity * Resolver.IterationTime, OriginalDelta.Velocity + ForceVelocity);

		Resolver.IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, OriginalDelta);
		return true;
	}

	void PreApplyResolvedData(UHazeMovementComponent MovementComponent) override
	{
		Super::PreApplyResolvedData(MovementComponent);
		
		FVector ForceVelocity = ForceDirection * ForceStrength;

		FMovementDelta OriginalDelta = Resolver.IterationState.GetDelta(EMovementIterationDeltaStateType::Movement);
		OriginalDelta = FMovementDelta(OriginalDelta.Delta - ForceVelocity * Resolver.IterationTime, OriginalDelta.Velocity - ForceVelocity);

		Resolver.IterationState.OverrideDelta(EMovementIterationDeltaStateType::Movement, OriginalDelta);
	}

#if !RELEASE
	void LogFinal(FTemporalLog ExtensionPage, FTemporalLog FinalSectionLog) const override
	{
		Super::LogFinal(ExtensionPage, FinalSectionLog);

		if(ForceComp == nullptr)
			return;

		FinalSectionLog.Value("ForceComp", ForceComp);
		FinalSectionLog.DirectionalArrow("ForceDirection", Resolver.Owner.ActorLocation, ForceDirection * 100.0);
		FinalSectionLog.Value("ForceStrength", ForceStrength);
	}
#endif
}

class UIslandEntranceSplineForceResolverExtensionComponent : UActorComponent
{
	AIslandEntranceForceSplineActor ForceSpline;
}

UCLASS(NotBlueprintable)
class AIslandEntranceForceSplineActor : ASplineActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent EnterTrigger;
	default EnterTrigger.ShapeColor = FLinearColor::Green;
	default EnterTrigger.EditorLineThickness = 3.0;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent ExitTrigger;
	default ExitTrigger.RelativeLocation = FVector(0.0, 100.0, 0.0);
	default ExitTrigger.ShapeColor = FLinearColor::Red;
	default ExitTrigger.EditorLineThickness = 3.0;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UIslandEntranceSplineForceVisualizerComponent VisualizerComp;
#endif

	UPROPERTY(EditAnywhere)
	float Radius = 3000.0;

	UPROPERTY(EditAnywhere)
	bool bUseResolver = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bUseResolver", EditConditionHides))
	float ForceStrength = 2500.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bUseResolver", EditConditionHides))
	float AccelerationStrength = 4000.0;

	UPROPERTY(EditAnywhere)
	float ForceStartAccelerationDuration = 2.0;

	UPROPERTY(EditAnywhere)
	float ForceStopAccelerationDuration = 2.0;

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve ForceCurve;
	default ForceCurve.AddDefaultKey(0.0, 0.0);
	default ForceCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	float ForceVisualizerSplineDistance = 0.0;

	UPROPERTY(EditAnywhere, Category = "Visualizer")
	bool bAnimateForceVisualizer = true;

	UPROPERTY(EditAnywhere, Category = "Visualizer", Meta = (EditCondition = "bAnimateForceVisualizer", EditConditionHides))
	float ForceVisualizerAnimationDuration = 1.0;

	UPROPERTY(EditAnywhere, Category = "Visualizer", Meta = (EditCondition = "!bAnimateForceVisualizer", EditConditionHides, ClampMin="0", ClampMax="1"))
	float ForceVisualizerAlpha = 0.0;

	TPerPlayer<FHazeAcceleratedFloat> AcceleratedForceStrength;
	TPerPlayer<float> CurrentAccelerationDuration;
	TPerPlayer<float> TargetForceStrength;
	TPerPlayer<bool> bApplyingForce;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		EnterTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterEnterTrigger");
		ExitTrigger.OnPlayerEnter.AddUFunction(this, n"OnEnterExitTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bUseResolver)
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				AcceleratedForceStrength[Player].AccelerateTo(TargetForceStrength[Player], CurrentAccelerationDuration[Player], DeltaTime);
				bool bForceIsRelevant = !Math::IsNearlyZero(AcceleratedForceStrength[Player].Value);
				if(bApplyingForce[Player] != bForceIsRelevant)
				{
					bApplyingForce[Player] = bForceIsRelevant;
					if(bApplyingForce[Player])
					{
						auto ExtensionComp = UIslandEntranceSplineForceResolverExtensionComponent::GetOrCreate(Player);
						ExtensionComp.ForceSpline = this;
						Player.ApplyResolverExtension(UIslandEntranceSplineForceResolverExtension, this);
					}
					else
					{
						auto ExtensionComp = UIslandEntranceSplineForceResolverExtensionComponent::GetOrCreate(Player);
						ExtensionComp.ForceSpline = nullptr;
						Player.ClearResolverExtension(UIslandEntranceSplineForceResolverExtension, this);
					}
				}
			}
		}
		else
		{
			for(AHazePlayerCharacter Player : Game::Players)
			{
				float Force = GetDistanceAlphaToCenter(Player.ActorLocation) * TargetForceStrength[Player];
				FVector Direction = GetDirectionForPlayer(Player);
				Player.SetActorHorizontalVelocity(Player.ActorHorizontalVelocity + Direction * Force * DeltaTime);
			}
		}
	}

	UFUNCTION()
	private void OnEnterEnterTrigger(AHazePlayerCharacter Player)
	{
		if(IsActorDisabled())
			return;

		StartForceForPlayer(Player);
		// Player.BlockCapabilities(PlayerMovementTags::AirDash, this);
		// Player.BlockCapabilities(PlayerMovementTags::AirJump, this);
	}

	UFUNCTION()
	private void OnEnterExitTrigger(AHazePlayerCharacter Player)
	{
		StopForceForPlayer(Player);
		// Player.UnblockCapabilities(PlayerMovementTags::AirDash, this);
		// Player.UnblockCapabilities(PlayerMovementTags::AirJump, this);
	}

	float GetForceStrengthForPlayer(AHazePlayerCharacter Player) const
	{
		float Alpha = GetDistanceAlphaToCenter(Player.ActorLocation);
		return Alpha * AcceleratedForceStrength[Player].Value;
	}

	FVector GetDirectionForPlayer(AHazePlayerCharacter Player) const
	{
		FTransform ClosestTransform = GetClosestTransform(Player.ActorLocation);
		return (ClosestTransform.Location - Player.ActorLocation).VectorPlaneProject(ClosestTransform.Rotation.ForwardVector).GetSafeNormal();
	}

	UFUNCTION()
	private void StartForceForPlayer(AHazePlayerCharacter Player)
	{
		TargetForceStrength[Player] = bUseResolver ? ForceStrength : AccelerationStrength;
		CurrentAccelerationDuration[Player] = ForceStartAccelerationDuration;
	}

	UFUNCTION()
	private void StopForceForPlayer(AHazePlayerCharacter Player)
	{
		TargetForceStrength[Player] = 0.0;
		CurrentAccelerationDuration[Player] = ForceStopAccelerationDuration;
	}

	FTransform GetClosestTransform(FVector Location) const
	{
		return Spline.GetClosestSplineWorldTransformToWorldLocation(Location);
	}

	float GetDistanceAlphaToCenter(FVector Location) const
	{
		FVector LocalLocation = GetClosestTransform(Location).InverseTransformPosition(Location);
		return GetLocalDistanceAlphaToCenter(LocalLocation);
	}

	// Takes a local location to the closest transform on the spline and returns the distance alpha to center
	float GetLocalDistanceAlphaToCenter(FVector LocalLocation) const
	{
		FVector Location = LocalLocation;
		Location.X = 0.0;

		float Alpha = Location.Size() / Radius;
		return ForceCurve.GetFloatValue(Alpha);
	}
}

#if EDITOR
class UIslandEntranceSplineForceVisualizerComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UIslandEntranceSplineForceVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UIslandEntranceSplineForceVisualizerComponent;

	const float VolumeLineThickness = 10.0;
	const FLinearColor VolumeColor = FLinearColor::LucBlue;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ForceSpline = Cast<AIslandEntranceForceSplineActor>(Component.Owner);
		UHazeSplineComponent Spline = ForceSpline.Spline;

		DrawVolume(Spline, ForceSpline);
		DrawForceVectors(Spline, ForceSpline);
	}

	void DrawVolume(UHazeSplineComponent Spline, AIslandEntranceForceSplineActor ForceComp)
	{
		const float StepDistance = 200.0;

		float CurrentDist = 0.0;
		FTransform CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);

		FVector Point1, Point2, Point3, Point4;
		GetCylinderEdgePoints(CurrentTransform, ForceComp, Point1, Point2, Point3, Point4);
		DrawScaledCircle(CurrentTransform, ForceComp.Radius);

		while(CurrentDist < Spline.SplineLength)
		{
			bool bFinal = false;
			CurrentDist += StepDistance;
			if(CurrentDist >= Spline.SplineLength)
			{
				CurrentDist = Spline.SplineLength;
				bFinal = true;
			}
			CurrentTransform = Spline.GetWorldTransformAtSplineDistance(CurrentDist);

			FVector Temp1, Temp2, Temp3, Temp4;
			GetCylinderEdgePoints(CurrentTransform, ForceComp, Temp1, Temp2, Temp3, Temp4);

			DrawLine(Point1, Temp1, VolumeColor, VolumeLineThickness);
			DrawLine(Point2, Temp2, VolumeColor, VolumeLineThickness);
			DrawLine(Point3, Temp3, VolumeColor, VolumeLineThickness);
			DrawLine(Point4, Temp4, VolumeColor, VolumeLineThickness);

			Point1 = Temp1;
			Point2 = Temp2;
			Point3 = Temp3;
			Point4 = Temp4;

			if(bFinal)
				DrawScaledCircle(CurrentTransform, ForceComp.Radius);
		}
	}

	void DrawForceVectors(UHazeSplineComponent Spline, AIslandEntranceForceSplineActor ForceComp)
	{
		float VectorMaxLength = ForceComp.Radius * 0.5;;

		const float LineThickness = VolumeLineThickness;
		const float SphereRadius = LineThickness * 2.0;

		FTransform RelevantTransform = Spline.GetWorldTransformAtSplineDistance(ForceComp.ForceVisualizerSplineDistance);
		FVector Center = RelevantTransform.Location;

		TArray<FVector> TargetLocations;
		TargetLocations.Add(FVector::RightVector * ForceComp.Radius);
		TargetLocations.Add(FVector::UpVector * ForceComp.Radius);
		TargetLocations.Add((FVector::RightVector + FVector::UpVector).GetSafeNormal() * ForceComp.Radius);

		float Alpha;
		if(ForceComp.bAnimateForceVisualizer)
			Alpha = Math::Saturate(Math::Fmod(Time::GameTimeSeconds, ForceComp.ForceVisualizerAnimationDuration) / ForceComp.ForceVisualizerAnimationDuration);
		else
			Alpha = ForceComp.ForceVisualizerAlpha;

		for(FVector TargetLocation : TargetLocations)
		{
			FVector LocalLocation = TargetLocation * Alpha;
			FVector WorldLocation = RelevantTransform.TransformPosition(LocalLocation);
			FVector CenterToLocationDir = (WorldLocation - Center).GetSafeNormal();

			float CounterForceAlpha = ForceComp.GetLocalDistanceAlphaToCenter(LocalLocation);

			DrawWireSphere(WorldLocation, SphereRadius, FLinearColor::Red, LineThickness);
			DrawArrow(WorldLocation, WorldLocation - CenterToLocationDir * (CounterForceAlpha * VectorMaxLength), FLinearColor::Red, 20.0, LineThickness);
			DrawArrow(WorldLocation, WorldLocation + CenterToLocationDir * VectorMaxLength, FLinearColor::Green, 20.0, LineThickness);
		}
	}

	void GetCylinderEdgePoints(FTransform CurrentTransform, AIslandEntranceForceSplineActor ForceComp, FVector&out Point1, FVector&out Point2, FVector&out Point3, FVector&out Point4)
	{
		Point1 = CurrentTransform.TransformPosition(FVector::RightVector * ForceComp.Radius);
		Point2 = CurrentTransform.TransformPosition(FVector::LeftVector * ForceComp.Radius);
		Point3 = CurrentTransform.TransformPosition(FVector::UpVector * ForceComp.Radius);
		Point4 = CurrentTransform.TransformPosition(FVector::DownVector * ForceComp.Radius);
	}

	void DrawScaledCircle(FTransform CurrentTransform, float BaseRadius, int Segments = 16)
	{
		float Step = 360.0 / Segments;
		FVector PreviousPoint = Math::RotatorFromAxisAndAngle(FVector(1.0, 0.0, 0.0), 0.0).UpVector * BaseRadius;
		for(int i = 1; i <= Segments; i++)
		{
			FVector NewPoint = Math::RotatorFromAxisAndAngle(FVector(1.0, 0.0, 0.0), Step * i).UpVector * BaseRadius;
			DrawLine(CurrentTransform.TransformPosition(PreviousPoint), CurrentTransform.TransformPosition(NewPoint), VolumeColor, VolumeLineThickness);
			PreviousPoint = NewPoint;
		}
	}
}
#endif