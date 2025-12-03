class UDiscSlideHydraExitGrindComponent : UBoxComponent
{
	bool bTriggered = false;
	ADiscSlideHydra Hydra;

	UPROPERTY(EditInstanceOnly)
	FVector ExitImpulse = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Hydra = Cast<ADiscSlideHydra>(Owner);
		OnComponentBeginOverlap.AddUFunction(this, n"TriggerBeginOverlap");
	}

	UFUNCTION()
	void TriggerBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (bTriggered)
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		TListedActors<ASlidingDisc> Discs;
		if (Discs.Num() == 0)
			return;
		ASlidingDisc Disc = Discs.Single;
		if (Disc == nullptr)
			return;
		if (Disc.GrindingOnHydra == nullptr)
			return;
		Disc.GrindingOnHydra.bManuallyHopOffGrind = true;
	}
}

#if EDITOR
class UDiscSlideHydraExitGrindComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UDiscSlideHydraExitGrindComponent;
	bool bIsOffsetSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto DiscExitComp = Cast<UDiscSlideHydraExitGrindComponent>(Component);

		FTransform CompTransform = DiscExitComp.WorldTransform;
		FVector ImpulseEndWorldLocation = CompTransform.TransformPosition(DiscExitComp.ExitImpulse);

		SetRenderForeground(true);
		SetHitProxy(n"EditableOffset", EVisualizerCursor::GrabHand);

		DrawArrow(DiscExitComp.WorldLocation, ImpulseEndWorldLocation, ColorDebug::Bubblegum, 75.0, 75.0);

		if (DiscExitComp.ExitImpulse.Size() > KINDA_SMALL_NUMBER)
		{
			FVector WorldImpulseDirection = ImpulseEndWorldLocation - DiscExitComp.WorldLocation;
			FVector CrossRight = FVector::UpVector.CrossProduct(WorldImpulseDirection).GetSafeNormal();
			FVector CrossUp = WorldImpulseDirection.CrossProduct(CrossRight).GetSafeNormal();
			DrawWorldString("Exit Force " + WorldImpulseDirection.Size(), DiscExitComp.WorldLocation + WorldImpulseDirection * 0.2);

			const float GravityMultiplier = 3.7;
			FVector FakeGravity = FVector::UpVector * -980.0 * GravityMultiplier;
			FVector FakeVelocity = WorldImpulseDirection;
			FVector FakeCurrentLocation = DiscExitComp.WorldLocation;
			const float FakeDrag = 0.2;

			// FVector Acceleration = SlidingDisc.Gravity * MovementComponent.GravityMultiplier + TurnForce - MovementComponent.Velocity * SlidingDisc.Drag + SlidingDisc.BoostForce;
			float FakeDeltaTimeStep = 1.0 / 10.0;
			for (int iSegment = 0; iSegment < 100; ++iSegment)
			{
				// ActivatedParams.Hydra.TriggerGrindingComp.GrindSpeed
				if (iSegment == 20)
					DrawWorldString("APPROX ARC\nDepends on animation!", FakeCurrentLocation);
					
				FakeVelocity += FakeGravity * FakeDeltaTimeStep;
				FakeVelocity -= FakeVelocity * FakeDrag * FakeDeltaTimeStep;
				FVector FakeDelta = FakeVelocity * FakeDeltaTimeStep;
				FVector FakeNextLocation = FakeCurrentLocation + FakeDelta;
				DrawArrow(FakeCurrentLocation, FakeNextLocation, ColorDebug::Eggblue, 20.0, 20.0);
				FakeCurrentLocation = FakeNextLocation;
			}

			for (int xGrid = -5; xGrid < 5; ++xGrid)
			{
				FVector RightOffset = CrossRight * xGrid * 700.0;
				DrawArrow(DiscExitComp.WorldLocation + RightOffset, ImpulseEndWorldLocation + RightOffset, ColorDebug::Lavender, 10.0, 5.0);
				FVector UpOffset = CrossUp * 700.0;
				DrawLine(DiscExitComp.WorldLocation + RightOffset, DiscExitComp.WorldLocation + RightOffset + UpOffset, ColorDebug::Eggblue, 5.0);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndEditing()
	{
		bIsOffsetSelected = false;
	}

	UFUNCTION(BlueprintOverride)
	bool VisProxyHandleClick(FName HitProxy, FVector ClickOrigin, FVector ClickDirection, FKey Key, EInputEvent Event)
	{
		if (HitProxy == n"EditableOffset")
		{
			bIsOffsetSelected = true;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetWidgetLocation(FVector& OutLocation) const
	{
		auto DiscExitComp = Cast<UDiscSlideHydraExitGrindComponent>(EditingComponent);
		if (bIsOffsetSelected)
		{
			// Override gizmo location so it's at our editable offset location
			FTransform CompTransform = DiscExitComp.WorldTransform;
			FVector ImpulseEndWorldLocation = CompTransform.TransformPosition(DiscExitComp.ExitImpulse);
			OutLocation = ImpulseEndWorldLocation;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool GetCustomInputCoordinateSystem(EVisualizerCoordinateSystem CoordSystem, EVisualizerWidgetMode WidgetMode, FTransform& OutTransform) const
	{
		if (!bIsOffsetSelected)
			return false;

		OutTransform = FTransform();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool HandleInputDelta(FVector& DeltaTranslate, FRotator& DeltaRotate, FVector& DeltaScale)
	{
		if (!bIsOffsetSelected)
			return false;

		auto DiscExitComp = Cast<UDiscSlideHydraExitGrindComponent>(EditingComponent);
		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = DiscExitComp.WorldTransform.InverseTransformVector(DeltaTranslate);
			DiscExitComp.ExitImpulse += LocalTranslation;
		}
		return true;
	}
}
#endif