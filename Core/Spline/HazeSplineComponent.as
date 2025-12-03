
UCLASS(NotPlaceable, ClassGroup = Utility, HideCategories = "HiddenSpline Tags Activation Debug Cooking Physics LOD AssetUserData Collision Rendering Lighting Navigation VirtualTexture Mobile HLOD PathTracing TextureStreaming")
class UHazeSplineComponent : UHazeSplineBaseComponent
{
	UPROPERTY(EditConst, EditInstanceOnly, BlueprintHidden, Category = "HiddenSpline")
	TArray<FHazeSplinePoint> SplinePoints;
	default SplinePoints.Add(FHazeSplinePoint());
	default SplinePoints.Add(FHazeSplinePoint(FVector(0.0, 100.0, 0.0)));

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (ShowOnlyInnerProperties))
	FHazeSplineSettings SplineSettings;

	UPROPERTY(EditAnywhere, BlueprintHidden, Meta = (ShowOnlyInnerProperties))
	FSplineEditingSettings EditingSettings;

	UPROPERTY(EditConst, EditInstanceOnly, BlueprintHidden, Category = "HiddenSpline")
	FHazeComputedSpline ComputedSpline;

	// Specify splines to connect to the start and end of this spline
	UPROPERTY(EditInstanceOnly, BlueprintHidden, Category = "Spline Connections")
	bool bSpecifyConnections = false;

	// Connect the end of the spline to the specified other spline
	UPROPERTY(EditInstanceOnly, BlueprintHidden, Category = "Spline Connections", Meta = (EditCondition = "bSpecifyConnections", EditConditionHides))
	FSpecifiedSplineConnection EndConnection;
	default EndConnection.ConnectType = ESpecifiedSplineConnectionType::ConnectToStartOfTarget;

	// Connect the end of the spline to the specified other spline
	UPROPERTY(EditInstanceOnly, BlueprintHidden, Category = "Spline Connections", Meta = (EditCondition = "bSpecifyConnections", EditConditionHides))
	FSpecifiedSplineConnection StartConnection;
	default StartConnection.ConnectType = ESpecifiedSplineConnectionType::ConnectToEndOfTarget;

	// Align the spline's last point so it's positioned at the connection point of its end connection
	UPROPERTY(EditInstanceOnly, BlueprintHidden, Category = "Spline Connections", Meta = (EditCondition = "bSpecifyConnections", EditConditionHides), AdvancedDisplay)
	bool bAlignLastPointToEndConnection = false;

	// Align the spline's first point so it's positioned at the connection point of its start connection
	UPROPERTY(EditInstanceOnly, BlueprintHidden, Category = "Spline Connections", Meta = (EditCondition = "bSpecifyConnections", EditConditionHides), AdvancedDisplay)
	bool bAlignFirstPointToStartConnection = false;

	// Runtime list of spline connections, not editable in editor
	UPROPERTY(Transient, NotEditable, BlueprintHidden)
	TArray<FSplineConnection> SplineConnections;

#if EDITOR
	UPROPERTY(EditConst, EditAnywhere, BlueprintHidden, Category = "HiddenSpline")
	FHazeSplineBuilderState BuilderState;
#endif

	UFUNCTION(BlueprintOverride)
	private void OnActorOwnerModifiedInEditor()
	{
		UpdateSpline();
		MarkRenderStateDirty();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Version++;

		if (bSpecifyConnections)
		{
			ApplySpecifiedConnection(false, 0.0, StartConnection);
			ApplySpecifiedConnection(true, GetSplineLength(), EndConnection);
		}
		// Add spline connections for the closed loop if we have one
		else if (SplineSettings.bClosedLoop)
		{
			FSplineConnection EndOfSplineConnection;
            EndOfSplineConnection.ExitSpline = this;
            EndOfSplineConnection.DistanceOnEntrySpline = ComputedSpline.SplineLength;
            EndOfSplineConnection.DistanceOnExitSpline = 0.0;
            EndOfSplineConnection.bCanEnterGoingForward = true;
            EndOfSplineConnection.bCanEnterGoingBackward = false;
            EndOfSplineConnection.bExitForwardOnSpline = true;
			EndOfSplineConnection.Instigator = this;
            AddSplineConnection(EndOfSplineConnection);

            FSplineConnection StartOfSplineConnection;
            StartOfSplineConnection.ExitSpline = this;
            StartOfSplineConnection.DistanceOnEntrySpline = 0.0;
            StartOfSplineConnection.DistanceOnExitSpline = ComputedSpline.SplineLength;
            StartOfSplineConnection.bCanEnterGoingForward = false;
            StartOfSplineConnection.bCanEnterGoingBackward = true;
            StartOfSplineConnection.bExitForwardOnSpline = false;
			StartOfSplineConnection.Instigator = this;
            AddSplineConnection(StartOfSplineConnection);
		}
	}

	private void ApplySpecifiedConnection(bool bFromForward, float AtDistance, FSpecifiedSplineConnection Spec)
	{
		if (Spec.ConnectTo.IsNull())
			return;
		
		AActor ConnectActor = Spec.ConnectTo.Get();
		if (ConnectActor == nullptr)
		{
			devError(f"Attempting to connect spline {GetPathName()} to {Spec.ConnectTo.ToString()} but it was not loaded or no longer exists.");
			return;
		}

		UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(ConnectActor);
		if (OtherSpline == nullptr)
		{
			devError(f"Attempting to connect spline {GetPathName()} to {Spec.ConnectTo.ToString()} but it did not have a spline component.");
			return;
		}

		FSplineConnection Connection;
		switch (Spec.ConnectType)
		{
			case ESpecifiedSplineConnectionType::ConnectToStartOfTarget:
				Connection.DistanceOnExitSpline = 0.0;
				Connection.bExitForwardOnSpline = true;
			break;
			case ESpecifiedSplineConnectionType::ConnectToEndOfTarget:
				Connection.DistanceOnExitSpline = OtherSpline.GetSplineLength();
				Connection.bExitForwardOnSpline = false;
			break;
			case ESpecifiedSplineConnectionType::ConnectToClosestPointOnTarget:
				Connection.DistanceOnExitSpline = OtherSpline.GetClosestSplineDistanceToWorldLocation(
					GetWorldLocationAtSplineDistance(AtDistance)
				);
				Connection.bExitForwardOnSpline = Spec.bForwardFacingOnTargetSpline;
			break;
			case ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget:
				Connection.DistanceOnExitSpline = Math::Clamp(Spec.DistanceOnTargetSpline, 0.0, OtherSpline.GetSplineLength());
				Connection.bExitForwardOnSpline = Spec.bForwardFacingOnTargetSpline;
			break;
		}

		Connection.ExitSpline = OtherSpline;
		Connection.DistanceOnEntrySpline = AtDistance;
		Connection.bCanEnterGoingForward = bFromForward;
		Connection.bCanEnterGoingBackward = !bFromForward;
		Connection.Instigator = this;
		AddSplineConnection(Connection);

		if (Spec.bMakeReciprocalConnection)
		{
			FSplineConnection Reverse;

			Reverse.ExitSpline = this;
			Reverse.Instigator = this;
			Reverse.bExitForwardOnSpline = !bFromForward;

			Reverse.DistanceOnEntrySpline = Connection.DistanceOnExitSpline;
			Reverse.DistanceOnExitSpline = Connection.DistanceOnEntrySpline;

			Reverse.bCanEnterGoingForward = !Connection.bExitForwardOnSpline;
			Reverse.bCanEnterGoingBackward = Connection.bExitForwardOnSpline;

			OtherSpline.AddSplineConnection(Reverse);
		}
	}

	void UpdateSpline()
	{
		Version++;

		// It is not possible to have 0 spline points in a spline
		if (SplinePoints.Num() == 0)
		{
			SplinePoints.Add(FHazeSplinePoint());
#if EDITOR
			OnEditorSplinePointAddedAtIndex(0);
#endif
		}

		// Align start and end points if we specified it
		if (bSpecifyConnections && SplinePoints.Num() >= 2)
		{
			if (bAlignFirstPointToStartConnection)
				AlignConnectionPoint(SplinePoints[0], SplinePoints[1], StartConnection);
			if (bAlignLastPointToEndConnection)
				AlignConnectionPoint(SplinePoints.Last(), SplinePoints.Last(1), EndConnection);
		}

		// Recompute the spline from spline points
		SplineComputation::ComputeSpline(SplineSettings, SplinePoints, ComputedSpline);

		// Dirty connections so we fix their display
		if (bSpecifyConnections)
		{
			AActor StartActor = EndConnection.ConnectTo.Get();
			if (StartActor != nullptr)
			{
				UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(StartActor);
				if (OtherSpline != nullptr)
					OtherSpline.MarkRenderStateDirty();
			}

			AActor EndActor = StartConnection.ConnectTo.Get();
			if (EndActor != nullptr)
			{
				UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(EndActor);
				if (OtherSpline != nullptr)
					OtherSpline.MarkRenderStateDirty();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	private void __Internal_GetSplineBoxBounds(FVector& OutCenter, FVector& OutBoxExtent) const
	{
		OutCenter = ComputedSpline.Bounds.Center;
		OutBoxExtent = ComputedSpline.Bounds.Extent;
	}

	UFUNCTION(BlueprintOverride)
	private void __Internal_GetSplineWorldBoxBounds(FVector& OutCenter, FVector& OutBoxExtent) const
	{
		FBox TransformedBounds = ComputedSpline.Bounds.TransformBy(GetWorldTransform());
		OutCenter = TransformedBounds.Center;
		OutBoxExtent = TransformedBounds.Extent;
	}

	UFUNCTION(BlueprintOverride)
	private float __Internal_GetSplineLength()
	{
		return ComputedSpline.SplineLength;
	}

	UFUNCTION(BlueprintOverride)
	private FTransform __Internal_GetWorldTransformAtSplineDistance(const float SplineDistance)
	{
		return SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, SplineDistance) * WorldTransform;
	}

	UFUNCTION(BlueprintOverride)
	private FTransform __Internal_GetRelativeTransformAtSplineDistance(const float SplineDistance)
	{
		return SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, SplineDistance);
	}

	UFUNCTION(BlueprintOverride)
	private TArray<FTransform> __Internal_GetRelativeSplinePointTransforms()
	{
		TArray<FTransform> RelativePointTransforms;
		RelativePointTransforms.Reserve(ComputedSpline.Points.Num());
		for(const auto& IterPoint : ComputedSpline.Points)
		{
			FTransform TM = FTransform(IterPoint.RelativeRotation, IterPoint.RelativeLocation, IterPoint.RelativeScale3D);
			RelativePointTransforms.Add(TM);
		}
		return RelativePointTransforms;
	}

	UFUNCTION(BlueprintOverride)
	private void __Internal_SetSplineData(TArray<FHazeSplinePoint> InPoints, FHazeSplineSettings InSettings)
	{
		SplinePoints = InPoints;
		SplineSettings.bClosedLoop = InSettings.bClosedLoop;
		UpdateSpline();
	}

	/**
	 * The total length of the spline.
	 */
	UFUNCTION(BlueprintPure, Category = "Spline")
	float GetSplineLength() const property
	{
		return ComputedSpline.SplineLength;
	}

	/**
	 * Whether this spline loops from end to start.
	 */
	UFUNCTION(BlueprintPure, Category = "Spline")
	bool IsClosedLoop() const
	{
		return SplineSettings.bClosedLoop;
	}

	/**
	 * The world position of the spline at the specified Spline fraction [0...1].
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldLocationAtSplineFraction(float Fraction) const
	{
		return WorldTransform.TransformPosition(
			SplineComputation::GetRelativeLocationAtSplineDistance(ComputedSpline, ComputedSpline.SplineLength * Fraction)
		);
	}

	/**
	 * The world rotation of the spline at the specified Spline fraction [0...1].
	 */
	UFUNCTION(BlueprintPure)
	FQuat GetWorldRotationAtSplineFraction(float Fraction) const
	{
		return WorldTransform.TransformRotation(
			SplineComputation::GetRelativeRotationAtSplineDistance(ComputedSpline, ComputedSpline.SplineLength * Fraction)
		);
	}

	/**
	 * The world scale of the spline at the specified Spline fraction [0..1].
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldScale3DAtSplineFraction(float Fraction) const
	{
		return WorldTransform.Scale3D * SplineComputation::GetRelativeScale3DAtSplineDistance(ComputedSpline, ComputedSpline.SplineLength * Fraction);
	}

	/**
	 * The world transform of the spline at the specified Spline fraction [0..1].
	 */
	UFUNCTION(BlueprintPure)
	FTransform GetWorldTransformAtSplineFraction(float Fraction) const
	{
		return SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, ComputedSpline.SplineLength * Fraction) * WorldTransform;
	}

	/**
	 * The world position of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldLocationAtSplineDistance(float SplineDistance) const
	{
		return WorldTransform.TransformPosition(
			SplineComputation::GetRelativeLocationAtSplineDistance(ComputedSpline, SplineDistance)
		);
	}

	/**
	 * The world rotation of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FQuat GetWorldRotationAtSplineDistance(float SplineDistance) const
	{
		return WorldTransform.TransformRotation(
			SplineComputation::GetRelativeRotationAtSplineDistance(ComputedSpline, SplineDistance)
		);
	}

	/**
	 * The world scale of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldScale3DAtSplineDistance(float SplineDistance) const
	{
		return WorldTransform.Scale3D * SplineComputation::GetRelativeScale3DAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The world transform of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FTransform GetWorldTransformAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, SplineDistance) * WorldTransform;
	}

	/**
	 * The world space tangent of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldTangentAtSplineDistance(float SplineDistance) const
	{
		return WorldTransform.TransformVector(SplineComputation::GetRelativeTangentAtSplineDistance(ComputedSpline, SplineDistance));
	}

	/**
	 * The world space forward direction on the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetWorldForwardVectorAtSplineDistance(float SplineDistance) const
	{
		return WorldTransform.TransformVector(SplineComputation::GetRelativeForwardVectorAtSplineDistance(ComputedSpline, SplineDistance));
	}

	/**
	 * The relative transform of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FTransform GetRelativeTransformAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeTransformAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The relative forward of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetRelativeForwardVectorAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeForwardVectorAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The relative position of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetRelativeLocationAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeLocationAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The relative rotation of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FQuat GetRelativeRotationAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeRotationAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The relative scale of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetRelativeScale3DAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeScale3DAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The relative space tangent of the spline at the specified spline distance.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetRelativeTangentAtSplineDistance(float SplineDistance) const
	{
		return SplineComputation::GetRelativeTangentAtSplineDistance(ComputedSpline, SplineDistance);
	}

	/**
	 * The closest spline distance to the specified world location.
	 */
	UFUNCTION(BlueprintPure)
	float GetClosestSplineDistanceToWorldLocation(FVector InWorldLocation) const
	{
		return SplineComputation::GetClosestSplineDistanceToRelativeLocation(
			ComputedSpline,
			WorldTransform.InverseTransformPosition(InWorldLocation)
		);
	}

	/**
	 * The closest spline distance to the specified relative location.
	 */
	UFUNCTION(BlueprintPure)
	float GetClosestSplineDistanceToRelativeLocation(FVector InRelativeLocation) const
	{
		return SplineComputation::GetClosestSplineDistanceToRelativeLocation(
			ComputedSpline,
			InRelativeLocation
		);
	}

	/**
	 * The closest world location on the spline to the specified world location.
	 */
	UFUNCTION(BlueprintPure)
	FVector GetClosestSplineWorldLocationToWorldLocation(FVector InWorldLocation) const
	{
		return WorldTransform.TransformPosition(
			SplineComputation::GetClosestRelativeLocationToRelativeLocation(
				ComputedSpline,
				WorldTransform.InverseTransformPosition(InWorldLocation)
			)
		);
	}

	/**
	 * The closest world rotation on the spline to the specified world location.
	 */
	UFUNCTION(BlueprintPure)
	FQuat GetClosestSplineWorldRotationToWorldLocation(FVector InWorldLocation) const
	{
		return WorldTransform.TransformRotation(
			SplineComputation::GetClosestRelativeRotationToRelativeLocation(
				ComputedSpline,
				WorldTransform.InverseTransformPosition(InWorldLocation)
			)
		);
	}

	/**
	 * The closest spline transform to the specified world location.
	 */
	UFUNCTION(BlueprintPure)
	FTransform GetClosestSplineWorldTransformToWorldLocation(FVector InWorldLocation) const
	{
		return SplineComputation::GetClosestTransformToRelativeLocation(
			ComputedSpline,
			WorldTransform.InverseTransformPosition(InWorldLocation)
		) * WorldTransform;
	}

	/**
	 * The spline distance when at the specified spline point that was edited into the spline.
	 */
	UFUNCTION(BlueprintPure)
	float GetSplineDistanceAtSplinePointIndex(int SplinePointIndex) const
	{
		if (!SplinePoints.IsValidIndex(SplinePointIndex))
			return -1.0;
		if(SplinePointIndex >= ComputedSpline.Points.Num())
			return -1.0;
		return ComputedSpline.Points[SplinePointIndex].SplineDistance;
	}

	/**
	 * How many points does the spline have.
	 */
	UFUNCTION(BlueprintPure)
	int GetNumSplinePoints() const
	{
		return SplinePoints.Num();
	}

	/**
	 * Get the radius for bounds that contains the whole spline.
	 */
	FSphere GetSplineBounds() const
	{
		FTransform CurrentTransform = GetWorldTransform();

		FSphere Sphere;
		Sphere.Center = CurrentTransform.TransformPosition(ComputedSpline.Bounds.Center);
		Sphere.W = CurrentTransform.Scale3D.AbsMax * ComputedSpline.BoundsRadius;
		return Sphere;
	}

	/**
	 * Get an FBox in the spline component's relative space that contains the entire spline.
	 */
	FBox GetRelativeBoxContainingEntireSpline() const
	{
		return ComputedSpline.Bounds;
	}

	/**
	 * Helper function to position a box component to contain the whole spline
	 */
	void PositionBoxComponentToContainEntireSpline(UBoxComponent BoxComponent, float ExpandMargin = 0.0) const
	{
		BoxComponent.WorldTransform = FTransform(ComputedSpline.Bounds.Center) * WorldTransform;
		BoxComponent.BoxExtent = (ComputedSpline.Bounds.Extent + FVector(ExpandMargin)).ComponentMax(FVector(1.0));
	}
	
	void AddSplineConnection(FSplineConnection Connection)
	{
		SplineConnections.Add(Connection);
	}

	void RemoveSplineConnection(FInstigator Instigator)
	{
		for (int32 i = 0, Count = SplineConnections.Num(); i < Count; ++i)
		{
			if (SplineConnections[i].Instigator == Instigator)
			{
				SplineConnections.RemoveAt(i);
				return;
			}
		}
	}

	void RemoveAllSplineConnections()
	{
		SplineConnections.Empty();
	}

	TArray<UHazeSplineComponent> GetAllLinkedSplines()
	{
		TArray<UHazeSplineComponent> Splines;
		Splines.Add(this);

		for (int i = 0; i < Splines.Num(); ++i)
		{
			UHazeSplineComponent CheckSpline = Splines[i];
			for (const FSplineConnection& Connection : CheckSpline.SplineConnections)
			{
				if (Connection.ExitSpline != nullptr)
					Splines.AddUnique(Connection.ExitSpline);
			}
		}

		return Splines;
	}

	private void AlignConnectionPoint(FHazeSplinePoint& Point, FHazeSplinePoint& AlignToPoint, FSpecifiedSplineConnection Spec)
	{
		AActor ConnectActor = Spec.ConnectTo.Get();
		if (ConnectActor == nullptr)
			return;

		UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(ConnectActor);
		if (OtherSpline == nullptr)
			return;

		float TargetDistance = 0.0;
		switch (Spec.ConnectType)
		{
			case ESpecifiedSplineConnectionType::ConnectToStartOfTarget:
				TargetDistance = 0.0;
			break;
			case ESpecifiedSplineConnectionType::ConnectToEndOfTarget:
				TargetDistance = OtherSpline.GetSplineLength();
			break;
			case ESpecifiedSplineConnectionType::ConnectToClosestPointOnTarget:
				TargetDistance = OtherSpline.GetClosestSplineDistanceToWorldLocation(
					WorldTransform.TransformPosition(AlignToPoint.RelativeLocation)
				);
			break;
			case ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget:
				TargetDistance = Math::Clamp(Spec.DistanceOnTargetSpline, 0.0, OtherSpline.GetSplineLength());
			break;
		}

		Point.RelativeLocation = WorldTransform.InverseTransformPosition(
			OtherSpline.GetWorldLocationAtSplineDistance(TargetDistance)
		);
	}

	/**
	 * Rendering for the spline in the editor viewport.
	 */
	// Update positions of the spline while moving the component
	default bRecreateRenderStateOnDrag = true;
	// Spline Editor Visualizer renders it while selected instead
	default bRenderWhileSelected = false;
	// Respond to the splines showflag
	default RenderShowFlag = EHazeEditorRenderedShowFlag::Splines;
	// We don't want this to be hidden in game because the Splines showflag already takes care of that
	default bHiddenInGame = false;

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		FBox TransformedBounds = ComputedSpline.Bounds.TransformBy(GetWorldTransform());

		OutOrigin = TransformedBounds.Center;
		OutBoxExtent = TransformedBounds.Extent;
		OutSphereRadius = OutBoxExtent.Size();
	}

	// Overridables for when spline points are added and removed to facilitate additional data:
	// Called when the user adds a new spline point in the editor
	void OnEditorSplinePointAddedAtIndex(int AddedSplinePointIndex) {}

	// Called when the user deletes a spline point in the editor
	void OnEditorSplinePointRemovedAtIndex(int RemovedSplinePointIndex) {}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		// Draw spline segments
		FTransform Transform = GetWorldTransform();

		int SampleCount = ComputedSpline.Samples_SplineAlpha.Num();
		int SampleStride = 1;
		int SegmentCount = ComputedSpline.Segments.Num();

		float SizeFactor = 1.0;

		FName SegmentProxy = n"SelectSpline";
		SetVisualizerHitProxy(SegmentProxy, EVisualizerCursor::CardinalCross);

		FLinearColor UnselectedColor = EditingSettings.SplineColor;
		UnselectedColor = UnselectedColor * 0.85;
		UnselectedColor.A = 1.0;

		// Some special rendering for when it's rendering in game
		if (World != nullptr && World.IsGameWorld())
		{
			UnselectedColor = EditingSettings.SplineColor;
			SizeFactor = 0.4;
			SetRenderForeground(true);
		}

		if (ComputedSpline.Samples_SegmentAlpha.Num() == 0)
			return;

		TArray<FVector> SegmentPoints;
		for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		{
			const FHazeComputedSplineSegment& Segment = ComputedSpline.Segments[SegmentIndex];
			float SegmentLength = Segment.EndSplineDistance - Segment.StartSplineDistance;
			if (SegmentLength == 0.0)
				continue;

			int DrawSampleCount = Math::Max(2, Segment.SampleCount);
			float PaddingAlpha = Math::Min(10.0 / SegmentLength, 0.4);
			float AlphaStep = (1.0 - (PaddingAlpha * 2.0)) / float(DrawSampleCount - 1);

			SegmentPoints.Reset();
			for (int DrawSample = 0; DrawSample < DrawSampleCount; ++DrawSample)
			{
				SegmentPoints.Add(SplineComputation::GetRelativeLocationAtSegmentAlpha(
					ComputedSpline,
					SegmentIndex,
					Math::Saturate(PaddingAlpha + (AlphaStep * DrawSample)),
				));
			}

			SetVisualizerHitProxy(SegmentProxy, EVisualizerCursor::CardinalCross);
			DrawLocalHierarchicalLineString(
				SegmentPoints,
				UnselectedColor,
				4.0 * SizeFactor, true
			);
		}

		ClearHitProxy();

		// Draw the are around the spline point without a hitproxy so we don't steal clicks from the spline points
		for (int SegmentIndex = 0; SegmentIndex < SegmentCount; ++SegmentIndex)
		{
			const FHazeComputedSplineSegment& Segment = ComputedSpline.Segments[SegmentIndex];
			float SegmentLength = Segment.EndSplineDistance - Segment.StartSplineDistance;
			if (SegmentLength == 0.0)
				continue;

			float PaddingAlpha = Math::Min(10.0 / SegmentLength, 0.4);

			DrawLocalLine(
				SplineComputation::GetRelativeLocationAtSegmentAlpha(
					ComputedSpline,
					SegmentIndex,
					0.0,
				),
				SplineComputation::GetRelativeLocationAtSegmentAlpha(
					ComputedSpline,
					SegmentIndex,
					PaddingAlpha,
				),
				UnselectedColor,
				4.0 * SizeFactor, true
			);
			DrawLocalLine(
				SplineComputation::GetRelativeLocationAtSegmentAlpha(
					ComputedSpline,
					SegmentIndex,
					1.0 - PaddingAlpha,
				),
				SplineComputation::GetRelativeLocationAtSegmentAlpha(
					ComputedSpline,
					SegmentIndex,
					1.0,
				),
				UnselectedColor,
				4.0 * SizeFactor, true
			);
		}

		ClearHitProxy();

		// Draw spline points
		for (int i = 0, Count = SplinePoints.Num(); i < Count; ++i)
		{
			const FHazeSplinePoint& Point = SplinePoints[i];

			FName PointProxy = n"SelectSplinePoint";
			PointProxy.SetNumber(i);

			// Draw the spline point sphere
			SetVisualizerHitProxy(PointProxy);
			DrawLocalPoint(
				Point.RelativeLocation,
				UnselectedColor,
				20.0 * SizeFactor,
			);
			ClearHitProxy();
		}

		// Draw connections if we have them
		if (bSpecifyConnections)
		{
			if (!bAlignFirstPointToStartConnection)
			{
				EditorRenderSplineConnection(
					0.0, FLinearColor::Red, 27.0, StartConnection, SizeFactor,
				);
			}

			if (!bAlignLastPointToEndConnection)
			{
				EditorRenderSplineConnection(
					GetSplineLength(), FLinearColor::Green, 21.0, EndConnection, SizeFactor,
				);
			}
		}
#endif
	}

#if EDITOR
	void EditorRenderSplineConnection(float FromDistance, FLinearColor Color, float Interval, FSpecifiedSplineConnection Spec, float SizeFactor)
	{
		AActor ConnectActor = Spec.ConnectTo.Get();
		if (ConnectActor == nullptr)
			return;

		UHazeSplineComponent OtherSpline = UHazeSplineComponent::Get(ConnectActor);
		if (OtherSpline == nullptr)
			return;

		float TargetDistance = 0.0;
		switch (Spec.ConnectType)
		{
			case ESpecifiedSplineConnectionType::ConnectToStartOfTarget:
				TargetDistance = 0.0;
			break;
			case ESpecifiedSplineConnectionType::ConnectToEndOfTarget:
				TargetDistance = OtherSpline.GetSplineLength();
			break;
			case ESpecifiedSplineConnectionType::ConnectToClosestPointOnTarget:
				TargetDistance = OtherSpline.GetClosestSplineDistanceToWorldLocation(
					GetWorldLocationAtSplineDistance(FromDistance)
				);
			break;
			case ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget:
				TargetDistance = Math::Clamp(Spec.DistanceOnTargetSpline, 0.0, OtherSpline.GetSplineLength());
			break;
		}

		DrawDashedLine(
			GetWorldLocationAtSplineDistance(FromDistance),
			OtherSpline.GetWorldLocationAtSplineDistance(TargetDistance),
			Color,
			Interval, 2.0 * SizeFactor, true
		);
	}
#endif

	void DrawDebug(int NumSegments = 100, FLinearColor Color = FLinearColor::White, float Thickness = 3.0, float Duration = 0.0)
	{
		float Interval = (1.0 / float(NumSegments));
		FVector PrevLoc = GetWorldLocationAtSplineFraction(0.0);
		for (float Fraction = Interval; Fraction < 1.0; Fraction += Interval)
		{
			FVector Loc = GetWorldLocationAtSplineFraction(Fraction);
			Debug::DrawDebugLine(PrevLoc, Loc, Color, Thickness, Duration);
			PrevLoc = Loc;
		}
		Debug::DrawDebugLine(PrevLoc, GetWorldLocationAtSplineFraction(1.0), Color, Thickness, Duration);
	}
};

enum ESplineHeightIndicatorMode
{
	// Don't show height indicators
	None,
	// Show a height indicator under each spline point, going to the lowest spline point's height
	SplinePointsToLowest,
	// Show a height indicator under each spline point, going infinitely downward
	SplinePointsToFloor,
	// Show height indicators underneath the whole spline, going to the lowest spline point's height
	WholeSplineToLowest,
	// Show height indicators underneath the whole spline, going infinitely downward
	WholeSplineToFloor,
};

struct FSplineEditingSettings
{
	// If false, spline is not rendered when selected
	UPROPERTY(EditDefaultsOnly, AdvancedDisplay, Category = "Spline Editing")
	bool bShowWhenSelected = true;

	// Whether to allow editing the spline at all
	UPROPERTY(EditAnywhere, AdvancedDisplay, Category = "Spline Editing")
	bool bAllowEditing = true;

	// Color to render the spline with in the editor
	UPROPERTY(EditAnywhere, AdvancedDIsplay, Category = "Spline Editing")
	FLinearColor SplineColor = FLinearColor::White;

	// Whether to visualize the spline's scale in the editor
	UPROPERTY(EditAnywhere, Category = "Spline Editing", Meta = (InlineEditConditionToggle))
	bool bEnableVisualizeScale = false;

	// Whether to visualize the spline's scale in the editor
	UPROPERTY(EditAnywhere, Category = "Spline Editing", Meta = (EditCondition = "bEnableVisualizeScale"))
	float VisualizeScale = 30.0;

	// Whether to visualize the roll of the spline by drawing upwards direction lines
	UPROPERTY(EditAnywhere, Category = "Spline Editing", Meta = (InlineEditConditionToggle), AdvancedDisplay)
	bool bEnableVisualizeRoll = false;

	// Whether to visualize the roll of the spline by drawing upwards direction lines
	UPROPERTY(EditAnywhere, Category = "Spline Editing", Meta = (EditCondition = "bEnableVisualizeRoll"), ADvancedDisplay)
	float VisualizeRoll = 30.0;

	// Draw directional arrows on the spline to indicate the forward direction
	UPROPERTY(EditAnywhere, Category = "Spline Editing", AdvancedDisplay)
	bool bVisualizeDirection = false;

	// Show height indicator lines underneath the spline
	UPROPERTY(EditAnywhere, Category = "Spline Editing")
	ESplineHeightIndicatorMode HeightIndicators = ESplineHeightIndicatorMode::WholeSplineToFloor;

	// Whether to select the spline component specifically while we're editing it
	UPROPERTY(NotEditable, Category = "Spline Editing")
	bool bSelectSplineComponentWhileEditing = true;
};

enum ESpecifiedSplineConnectionType
{
	// Connect to the start of the target spline
	ConnectToStartOfTarget,
	// Connect to the end of the target spline
	ConnectToEndOfTarget,
	// Connect to the closest point on the target spline
	ConnectToClosestPointOnTarget,
	// Connect to a point on the target spline at the specified distance
	ConnectToSpecifiedDistanceOnTarget,
};

struct FSpecifiedSplineConnection
{
	// Actor holding the spline component to connect the spline to
	UPROPERTY(EditInstanceOnly, Category = "Spline Connections")
	TSoftObjectPtr<AActor> ConnectTo;

	// Where to connect on the other spline
	UPROPERTY(EditInstanceOnly, Category = "Spline Connections")
	ESpecifiedSplineConnectionType ConnectType = ESpecifiedSplineConnectionType::ConnectToStartOfTarget;

	// Whether to end up facing forward on the target spline after taking the connection
	UPROPERTY(EditInstanceOnly, Category = "Spline Connections", Meta = (EditCondition = "ConnectType == ESpecifiedSplineConnectionType::ConnectToClosestPointOnTarget || ConnectType == ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget", EditConditionHides))
	bool bForwardFacingOnTargetSpline = true;

	// Distance on the target spline to connect to
	UPROPERTY(EditInstanceOnly, Category = "Spline Connections", Meta = (EditCondition = "ConnectType == ESpecifiedSplineConnectionType::ConnectToSpecifiedDistanceOnTarget", EditConditionHides))
	float DistanceOnTargetSpline = 0.0;

	// Whether to generate a backwards connection on the target spline as well
	UPROPERTY(EditInstanceOnly, Category = "Spline Connections", AdvancedDisplay)
	bool bMakeReciprocalConnection = true;
};

struct FSplineConnection
{
	bool bCanEnterGoingForward = true;
	bool bCanEnterGoingBackward = true;
	float DistanceOnEntrySpline = 0.0;
	float DistanceOnExitSpline = 0.0;
	UHazeSplineComponent ExitSpline = nullptr;
	bool bExitForwardOnSpline = true;
	FInstigator Instigator;
};