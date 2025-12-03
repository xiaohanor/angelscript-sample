struct FSketchbookPencilEraseObjectActivateParams
{
	USketchbookDrawableObjectComponent DrawableObjectComp;
};


struct FSketchbookPencilEraseObjectDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilEraseObjectCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASketchbookPencil Pencil;
	USketchbookDrawableObjectComponent DrawableObjectComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Pencil = Cast<ASketchbookPencil>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookPencilEraseObjectActivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return false;

		if(!Pencil.CurrentRequest.IsSet())
			return false;
		
		FSketchbookPencilRequest Request = Pencil.CurrentRequest.GetValue();

		if(!Request.bErase)
			return false;

		// Wait until the pencil has turned around
		if(Pencil.GetPivotState() != ESketchbookPencilPivotState::Erasing)
			return false;

		auto Drawable = Cast<USketchbookDrawableObjectComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;

		Params.DrawableObjectComp = Drawable;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilEraseObjectDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.CurrentRequest.IsSet())
			return true;

		if(Pencil.CurrentRequest.Value.WasInterrupted())
			return true;

		if(ActiveDuration > DrawableObjectComp.EraseTime)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilEraseObjectActivateParams Params)
	{
		DrawableObjectComp = Params.DrawableObjectComp;

		USketchbookPencilEventHandler::Trigger_OnStartErasingObject(Pencil, FSketchbookPencilEraseObjectParams(DrawableObjectComp));

		Pencil.OnStartErasing(DrawableObjectComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilEraseObjectDeactivateParams Params)
	{
		USketchbookPencilEventHandler::Trigger_OnFinishedErasingObject(Pencil);
		
		if(Params.bFinished)
			Pencil.OnFinishedErasing(DrawableObjectComp);
		else
			Pencil.OnInterrupted(DrawableObjectComp);

		DrawableObjectComp = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DrawableObjectComp.EraseTime);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);

		const float EraseAlpha = 1.0 - Alpha;

		const FVector StartLocation = DrawableObjectComp.GetDiagonalStartLocation(true, DrawableObjectComp.ErasePattern.DiagonalDirection);
		const FVector EndLocation = DrawableObjectComp.GetDiagonalEndLocation(true, DrawableObjectComp.ErasePattern.DiagonalDirection);

		FVector LineLocation = Math::Lerp(StartLocation, EndLocation, Alpha);
		LineLocation = Sketchbook::ProjectWorldLocationToPagePlane(LineLocation);

		Pencil.MoveAccelerateTo(LineLocation, 0.05, DeltaTime, this);

		FVector FirstOrthogonalDirection;
		FVector SecondOrthogonalDirection;
		DrawableObjectComp.GetOrthogonalVectors(DrawableObjectComp.ErasePattern.DiagonalDirection, FirstOrthogonalDirection, SecondOrthogonalDirection);

		FPlane PencilPlane = DrawableObjectComp.CalculateRevealPlane(Alpha, true);
		PencilPlane = Sketchbook::GetPencilPlane(Pencil.ActorLocation, PencilPlane.Normal);
		DrawableObjectComp.UpdateDrawnFraction(EraseAlpha, true, PencilPlane);

		const FVector TopLeft = DrawableObjectComp.GetDiagonalStartLocation(true, ESketchbookDrawableObjectDirection::TopLeftToBottomRight);
		const FVector BottomRight = DrawableObjectComp.GetDiagonalStartLocation(true, ESketchbookDrawableObjectDirection::BottomRightToTopLeft);
		const FVector SideToSideTopRight = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, FirstOrthogonalDirection);
		const FVector SideToSideBottomLeft = Sketchbook::GetRayRectangleIntersection(TopLeft, BottomRight, LineLocation, SecondOrthogonalDirection);

		const float SideToSideSpeed = Math::Lerp(
			DrawableObjectComp.ErasePattern.DiagonalWiggleFrequency.Min,
			DrawableObjectComp.ErasePattern.DiagonalWiggleFrequency.Max,
			Alpha
		);

		const float SideToSideAlpha = (Math::Sin(ActiveDuration * SideToSideSpeed) + 1) / 2;
		
		FVector SideToSideOffset = Math::Lerp(SideToSideBottomLeft, SideToSideTopRight, SideToSideAlpha);
		SideToSideOffset -= LineLocation;
		Pencil.MoveTipOffsetAccelerateTo(SideToSideOffset, 0.01, DeltaTime, this);
	}
};