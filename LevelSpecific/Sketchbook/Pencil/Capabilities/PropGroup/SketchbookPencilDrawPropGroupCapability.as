struct FSketchbookPencilDrawPropGroupActivateParams
{
	USketchbookDrawablePropGroupComponent DrawablePropGroup;
};

struct FSketchbookPencilDrawPropGroupDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilDrawPropGroupCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASketchbookPencil Pencil;
	USketchbookDrawablePropGroupComponent DrawablePropGroup;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilDrawPropGroupActivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return false;

		if(!Pencil.CurrentRequest.IsSet())
			return false;

		FSketchbookPencilRequest Request = Pencil.CurrentRequest.GetValue();

		if(Request.bErase)
			return false;

		// Wait until the pencil has turned around
		if(Pencil.GetPivotState() != ESketchbookPencilPivotState::Drawing)
			return false;

		auto Drawable = Cast<USketchbookDrawablePropGroupComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;

		Params.DrawablePropGroup = Drawable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilDrawPropGroupDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.CurrentRequest.IsSet())
			return true;

		if(Pencil.CurrentRequest.Value.WasInterrupted())
			return true;

		if(ActiveDuration > DrawablePropGroup.DrawTime)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilDrawPropGroupActivateParams Params)
	{
		DrawablePropGroup = Params.DrawablePropGroup;

		Pencil.OnStartDrawing(DrawablePropGroup);

		USketchbookPencilEventHandler::Trigger_OnStartDrawingPropGroup(Pencil, FSketchbookPencilDrawPropGroupParams(DrawablePropGroup));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilDrawPropGroupDeactivateParams Params)
	{
		USketchbookPencilEventHandler::Trigger_OnFinishedDrawingPropGroup(Pencil);
		
		if(Params.bFinished)
			Pencil.OnFinishedDrawing(DrawablePropGroup);
		else
			Pencil.OnInterrupted(DrawablePropGroup);

		DrawablePropGroup = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DrawablePropGroup.DrawTime);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		const FVector StartLocation = DrawablePropGroup.GetDiagonalStartLocation(DrawablePropGroup.DrawPattern.DiagonalDirection);
		const FVector EndLocation = DrawablePropGroup.GetDiagonalEndLocation(DrawablePropGroup.DrawPattern.DiagonalDirection);

		FVector LineLocation = Math::Lerp(StartLocation, EndLocation, Alpha);

		Pencil.MoveAccelerateTo(LineLocation, 0.05, DeltaTime, this);

		FVector FirstOrthogonalDirection;
		FVector SecondOrthogonalDirection;
		DrawablePropGroup.GetOrthogonalVectors(DrawablePropGroup.DrawPattern.DiagonalDirection, FirstOrthogonalDirection, SecondOrthogonalDirection);

		FPlane PencilPlane = DrawablePropGroup.CalculateRevealPlane(Alpha, false);

		PencilPlane = Sketchbook::GetPencilPlane(Pencil.ActorLocation, PencilPlane.Normal);
		DrawablePropGroup.UpdateDrawnFraction(Alpha, false, PencilPlane);

		const FVector TopLeft = DrawablePropGroup.GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight);
		const FVector BottomRight = DrawablePropGroup.GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft);
		const FVector SideToSideTopRight = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, FirstOrthogonalDirection);
		const FVector SideToSideBottomLeft = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, SecondOrthogonalDirection);

		const float SideToSideSpeed = Math::Lerp(
			DrawablePropGroup.DrawPattern.DiagonalWiggleFrequency.Min,
			DrawablePropGroup.DrawPattern.DiagonalWiggleFrequency.Max,
			Alpha
		);

		const float SideToSideAlpha = (Math::Sin(ActiveDuration * SideToSideSpeed) + 1) / 2;
		
		FVector SideToSideOffset = Math::Lerp(SideToSideBottomLeft, SideToSideTopRight, SideToSideAlpha);
		SideToSideOffset -= LineLocation;

		Pencil.MoveTipOffsetAccelerateTo(SideToSideOffset, 0.01, DeltaTime, this);

#if !RELEASE
		TEMPORAL_LOG(Pencil).Page("Prop Group")
			.Section("Draw")
			.Value("Alpha", Alpha)
			.Plane("Pencil Plane", Pencil.ActorLocation, PencilPlane.Normal)
		;
#endif
	}
};