struct FSketchbookPencilErasePropGroupActivateParams
{
	USketchbookDrawablePropGroupComponent DrawablePropGroup;
};

struct FSketchbookPencilErasePropGroupDeactivateParams
{
	bool bFinished = false;
};

class USketchbookPencilErasePropGroupCapability : UHazeCapability
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
	bool ShouldActivate(FSketchbookPencilErasePropGroupActivateParams& Params) const
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

		auto Drawable = Cast<USketchbookDrawablePropGroupComponent>(Request.Drawable);
		if(Drawable == nullptr)
			return false;
		
		Params.DrawablePropGroup = Drawable;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSketchbookPencilErasePropGroupDeactivateParams& Params) const
	{
		if(!Pencil.bIsActive)
			return true;

		if(!Pencil.CurrentRequest.IsSet())
			return true;

		if(Pencil.CurrentRequest.Value.WasInterrupted())
			return true;

		if(ActiveDuration > DrawablePropGroup.EraseTime)
		{
			Params.bFinished = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookPencilErasePropGroupActivateParams Params)
	{
		DrawablePropGroup = Params.DrawablePropGroup;

		Pencil.OnStartErasing(DrawablePropGroup);

		USketchbookPencilEventHandler::Trigger_OnStartErasingPropGroup(Pencil, FSketchbookPencilErasePropGroupParams(DrawablePropGroup));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSketchbookPencilErasePropGroupDeactivateParams Params)
	{
		USketchbookPencilEventHandler::Trigger_OnFinishedErasingPropGroup(Pencil);

		if(Params.bFinished)
			Pencil.OnFinishedErasing(DrawablePropGroup);
		else
			Pencil.OnInterrupted(DrawablePropGroup);

		DrawablePropGroup = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = Math::Saturate(ActiveDuration / DrawablePropGroup.EraseTime);
		Alpha = Math::EaseInOut(0, 1, Alpha, 2);
		const float EraseAlpha = 1.0 - Alpha;

		const FVector StartLocation = DrawablePropGroup.GetDiagonalStartLocation(DrawablePropGroup.ErasePattern.DiagonalDirection);
		const FVector EndLocation = DrawablePropGroup.GetDiagonalEndLocation(DrawablePropGroup.ErasePattern.DiagonalDirection);

		FVector LineLocation = Math::Lerp(StartLocation, EndLocation, Alpha);

		Pencil.MoveAccelerateTo(LineLocation, 0.05, DeltaTime, this);

		FVector FirstOrthogonalDirection;
		FVector SecondOrthogonalDirection;
		DrawablePropGroup.GetOrthogonalVectors(DrawablePropGroup.ErasePattern.DiagonalDirection, FirstOrthogonalDirection, SecondOrthogonalDirection);

		FPlane PencilPlane = DrawablePropGroup.CalculateRevealPlane(Alpha, true);
		PencilPlane = Sketchbook::GetPencilPlane(Pencil.ActorLocation, PencilPlane.Normal);

		DrawablePropGroup.UpdateDrawnFraction(EraseAlpha, true, PencilPlane);

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
			.Section("Erase")
			.Value("Alpha", Alpha)
			.Plane("Pencil Plane", Pencil.ActorLocation, PencilPlane.Normal)
		;
#endif
	}
};