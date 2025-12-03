struct FSketchbookPencilDrawObjectActivateParams
{
	USketchbookDrawableObjectComponent DrawableObject;
};

struct FSketchbookPencilDrawObjectDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilDrawObjectCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASketchbookPencil Pencil;
	USketchbookDrawableObjectComponent DrawableObject;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilDrawObjectActivateParams& Params) const
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

		USketchbookDrawableObjectComponent Drawable = Cast<USketchbookDrawableObjectComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;

		Params.DrawableObject = Drawable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilDrawObjectDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.CurrentRequest.IsSet())
			return true;

		if(Pencil.CurrentRequest.Value.WasInterrupted())
			return true;

		if(ActiveDuration > DrawableObject.DrawTime)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilDrawObjectActivateParams Params)
	{
		DrawableObject = Params.DrawableObject;

		Pencil.OnStartDrawing(DrawableObject);

		USketchbookPencilEventHandler::Trigger_OnStartDrawingObject(Pencil, FSketchbookPencilDrawObjectParams(DrawableObject));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilDrawObjectDeactivateParams Params)
	{
		USketchbookPencilEventHandler::Trigger_OnFinishedDrawingObject(Pencil);
		
		if(Params.bFinished)
			Pencil.OnFinishedDrawing(DrawableObject);
		else
			Pencil.OnInterrupted(DrawableObject);

		DrawableObject = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DrawableObject.DrawTime);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		const FVector StartLocation = DrawableObject.GetDiagonalStartLocation(false, DrawableObject.DrawPattern.DiagonalDirection);
		const FVector EndLocation = DrawableObject.GetDiagonalEndLocation(false, DrawableObject.DrawPattern.DiagonalDirection);

		FVector LineLocation = Math::Lerp(StartLocation, EndLocation, Alpha);
		LineLocation = Sketchbook::ProjectWorldLocationToPagePlane(LineLocation);

		Pencil.MoveAccelerateTo(LineLocation, 0.05, DeltaTime, this);

		FVector FirstOrthogonalDirection;
		FVector SecondOrthogonalDirection;
		DrawableObject.GetOrthogonalVectors(DrawableObject.DrawPattern.DiagonalDirection, FirstOrthogonalDirection, SecondOrthogonalDirection);

		FPlane PencilPlane = DrawableObject.CalculateRevealPlane(Alpha, false);
		PencilPlane = Sketchbook::GetPencilPlane(Pencil.ActorLocation, PencilPlane.Normal);
		DrawableObject.UpdateDrawnFraction(Alpha, true, PencilPlane);

		const FVector TopLeft = DrawableObject.GetDiagonalStartLocation(false, ESketchbookDrawableObjectDirection::TopLeftToBottomRight);
		const FVector BottomRight = DrawableObject.GetDiagonalStartLocation(false, ESketchbookDrawableObjectDirection::BottomRightToTopLeft);
		
		const FVector SideToSideTopRightOffset = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, FirstOrthogonalDirection);
		const FVector SideToSideBottomLeftOffset = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, SecondOrthogonalDirection);

		const float SideToSideSpeed = Math::Lerp(
			DrawableObject.DrawPattern.DiagonalWiggleFrequency.Min,
			DrawableObject.DrawPattern.DiagonalWiggleFrequency.Max,
			Alpha
		);

		const float SideToSideAlpha = (Math::Sin(ActiveDuration * SideToSideSpeed) + 1) / 2;
		
		FVector SideToSideOffset = Math::Lerp(SideToSideBottomLeftOffset, SideToSideTopRightOffset, SideToSideAlpha);

		SideToSideOffset -= LineLocation;
		Pencil.MoveTipOffsetAccelerateTo(SideToSideOffset, 0.01, DeltaTime, this);
	}
};