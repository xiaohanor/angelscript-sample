class USlidingDiscSpeedBoostComponent : UBoxComponent
{
	UPROPERTY(EditAnywhere)
	FVector SpeedBoost = FVector::ZeroVector;

	ASlidingDisc Disc = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnComponentBeginOverlap.AddUFunction(this, n"HandlePlayerEnter");
		OnComponentEndOverlap.AddUFunction(this, n"HandlePlayerLeave");
	}

	UFUNCTION()
	void HandlePlayerEnter(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		auto Disco = Cast<ASlidingDisc>(OtherActor);
		if (Disco == nullptr || Disc != nullptr)
			return;
		Disc = Disco;
		Disc.BoostForce = SpeedBoost;
	}

	UFUNCTION()
	private void HandlePlayerLeave(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		auto TheDisc = Cast<ASlidingDisc>(OtherActor);
		if (TheDisc == nullptr || Disc == nullptr)
			return;
		Disc.BoostForce = FVector::ZeroVector;
		Disc = nullptr;
	}
}

#if EDITOR
class USlidingDiscSpeedBoostComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USlidingDiscSpeedBoostComponent;
	bool bIsOffsetSelected = false;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto BoostComp = Cast<USlidingDiscSpeedBoostComponent>(Component);

		FTransform CompTransform = BoostComp.WorldTransform;
		FVector ImpulseEndWorldLocation = CompTransform.TransformPosition(BoostComp.SpeedBoost);

		SetRenderForeground(true);
		SetHitProxy(n"EditableOffset", EVisualizerCursor::GrabHand);

		DrawArrow(BoostComp.WorldLocation, ImpulseEndWorldLocation, ColorDebug::Bubblegum, 75.0, 75.0);

		if (BoostComp.SpeedBoost.Size() > KINDA_SMALL_NUMBER)
		{
			FVector WorldImpulseDirection = ImpulseEndWorldLocation - BoostComp.WorldLocation;
			FVector CrossRight = FVector::UpVector.CrossProduct(WorldImpulseDirection).GetSafeNormal();
			FVector CrossUp = WorldImpulseDirection.CrossProduct(CrossRight).GetSafeNormal();
			DrawWorldString("Exit Force " + WorldImpulseDirection.Size(), BoostComp.WorldLocation + WorldImpulseDirection * 0.2);
			for (int xGrid = -5; xGrid < 5; ++xGrid)
			{
				FVector RightOffset = CrossRight * xGrid * 700.0;
				DrawArrow(BoostComp.WorldLocation + RightOffset, ImpulseEndWorldLocation + RightOffset, ColorDebug::Lavender, 10.0, 5.0);
				FVector UpOffset = CrossUp * 700.0;
				DrawLine(BoostComp.WorldLocation + RightOffset, BoostComp.WorldLocation + RightOffset + UpOffset, ColorDebug::Eggblue, 5.0);
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
		auto BoostComp = Cast<USlidingDiscSpeedBoostComponent>(EditingComponent);
		if (bIsOffsetSelected)
		{
			// Override gizmo location so it's at our editable offset location
			FTransform CompTransform = BoostComp.WorldTransform;
			FVector ImpulseEndWorldLocation = CompTransform.TransformPosition(BoostComp.SpeedBoost);
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

		auto BoostComp = Cast<USlidingDiscSpeedBoostComponent>(EditingComponent);
		if (!DeltaTranslate.IsNearlyZero())
		{
			FVector LocalTranslation = BoostComp.WorldTransform.InverseTransformVector(DeltaTranslate);
			BoostComp.SpeedBoost += LocalTranslation;
		}
		return true;
	}
}
#endif