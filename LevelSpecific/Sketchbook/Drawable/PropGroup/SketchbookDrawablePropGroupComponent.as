enum ESketchbookDrawablePropGroupDirection
{
	TopLeftToBottomRight,
	TopRightToBottomLeft,
	BottomLeftToTopRight,
	BottomRightToTopLeft,
};

struct FSketchbookDrawablePropGroupPattern
{
	UPROPERTY(EditAnywhere)
	bool bPickClosestDirection = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bPickClosestDirection", EditConditionHides))
	ESketchbookDrawablePropGroupDirection DiagonalDirection = ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight;

	/**
	 * Will be lerped from Min to Max over the pattern duration.
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Type == ESketchbookDrawableObjectPatternType::Diagonal", EditConditionHides))
	FHazeRange DiagonalWiggleFrequency = FHazeRange(10, 20);
};

class USketchbookDrawablePropGroupComponent : USketchbookDrawableComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Drawable Prop Group")
	TArray<ASketchbookDrawableProp> Props;

	/**
	 * If assigned, this prop group will be erased while we are drawn
	 */
	UPROPERTY(EditInstanceOnly, Category = "Drawable Prop Group")
	TSoftObjectPtr<ASketchbookDrawablePropGroup> ReplacePropGroup;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Material")
	UMaterialInterface SketchbookMaterial;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Bounds")
	bool bAutomaticBounds = false;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Bounds", Meta = (EditCondition = "!bAutomaticBounds"))
	FVector2D Origin;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Bounds", Meta = (EditCondition = "!bAutomaticBounds"))
	FVector2D Extents;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Draw")
	float DrawTime = 1.0;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Draw")
	FSketchbookDrawablePropGroupPattern DrawPattern;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Erase")
	float EraseTime = 2.0;

	UPROPERTY(EditAnywhere, Category = "Drawable Prop Group|Erase")
	FSketchbookDrawablePropGroupPattern ErasePattern;
	default ErasePattern.bPickClosestDirection = true;

#if EDITOR
	void UpdateInEditor(bool bForce) override
	{
		for(auto Prop : Props)
		{
			if(Prop == nullptr)
				continue;

			Prop.DrawableComp.UpdateInEditor(bForce);
		}

		if(Extents.IsNearlyZero() || bAutomaticBounds)
			FitBounds();

		if(SketchbookMaterial == nullptr)
		{
			SketchbookMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Script/Engine.Material'/Game/LevelSpecific/Sketchbook/Shaders/Reveal/M_SketchBook_MeshReveal.M_SketchBook_MeshReveal'"));
			check(SketchbookMaterial != nullptr, "Failed to load M_SketchBook_MeshReveal. Has it been moved?");
		}

		const FPlane RevealPlane = CalculateRevealPlane(
			PreviewFraction,
			bPreviewErase
		);

		for(auto Prop : Props)
		{
			if(Prop == nullptr)
				continue;

			if(Prop.MeshComp.StaticMesh == nullptr)
				continue;

			Prop.DrawableComp.bDrawnFromStart = bDrawnFromStart;
			// Prop.DrawableComp.SketchbookMaterial = SketchbookMaterial;

			// Copy bounds to props
			Prop.DrawableComp.bAutomaticBounds = false;

			Prop.DrawableComp.bPreviewErase = bPreviewErase;
			Prop.DrawableComp.PreviewFraction = PreviewFraction;
			Prop.DrawableComp.UpdateInEditor(bForce);

			Prop.MeshComp.SetScalarParameterValueOnMaterials(
				n"RevealFraction",
				PreviewFraction
			);

			Prop.MeshComp.SetColorParameterValueOnMaterials(
				n"RevealPlane",
				FLinearColor(
					RevealPlane.X,
					RevealPlane.Y,
					RevealPlane.Z,
					RevealPlane.W
				)
			);
		}
		
		Cast<ASketchbookDrawablePropGroup>(Owner).DrawableAudioComp.UpdateInEditor(PreviewFraction);		
	}

	UFUNCTION(CallInEditor, Category = "Drawable Prop Group")
	void FitBounds()
	{
		FScopedTransaction Transaction("FitBounds");
		Modify();

		FVector WorldOrigin, WorldExtents;
		CalculateEditorBounds(WorldOrigin, WorldExtents);
		Origin = FVector2D(WorldOrigin.Y, WorldOrigin.Z) - FVector2D(Owner.ActorLocation.Y, Owner.ActorLocation.Z);
		Extents = FVector2D(WorldExtents.Y, WorldExtents.Z);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		// Remove any nullptr
		int Num = Props.Remove(nullptr);

		if(Num > 0)
			PrintWarning(f"PropGroup {Owner.GetActorNameOrLabel()} had {Num} null prop references!");

		if(Props.IsEmpty())
			PrintWarning(f"PropGroup {Owner.GetActorNameOrLabel()} had no props assigned!");
	}

	FVector GetWorldOrigin() const
	{
		return FVector(0, Owner.ActorLocation.Y, Owner.ActorLocation.Z) + FVector(0, Origin.X, Origin.Y);
	}

	void GetWorldBounds(FVector&out OutOrigin, FVector&out OutExtents) const
	{
		OutOrigin = GetWorldOrigin();
		OutExtents = FVector(0, Extents.X, Extents.Y);
	}

	void GetWorldBounds2D(FVector2D&out OutOrigin, FVector2D&out OutExtents) const
	{
		OutOrigin = FVector2D(Owner.ActorLocation.Y, Owner.ActorLocation.Z) + Origin;
		OutExtents = Extents;
	}

	void GetWorldMinMax(FVector&out OutMin, FVector&out OutMax) const
	{
		FVector WorldOrigin, WorldExtents;
		GetWorldBounds(WorldOrigin, WorldExtents);
		
		OutMin = WorldOrigin - WorldExtents;
		OutMax = WorldOrigin + WorldExtents;
	}

	void GetWorldMinMax2D(FVector2D&out OutMin, FVector2D&out OutMax) const
	{
		FVector2D WorldOrigin, WorldExtents;
		GetWorldBounds2D(WorldOrigin, WorldExtents);
		
		OutMin = WorldOrigin - WorldExtents;
		OutMax = WorldOrigin + WorldExtents;
	}

	FPlane CalculateRevealPlane(float RevealFraction, bool bErase) const
	{
		FVector Start;
		FVector End;
		FVector Normal;

		if(bErase)
		{
			Start = GetDiagonalEndLocation(ErasePattern.DiagonalDirection);
			End = GetDiagonalStartLocation(ErasePattern.DiagonalDirection);
			Normal = -GetDrawNormal(ErasePattern.DiagonalDirection);
		}
		else
		{
			Start = GetDiagonalStartLocation(DrawPattern.DiagonalDirection);
			End = GetDiagonalEndLocation(DrawPattern.DiagonalDirection);
			Normal = GetDrawNormal(DrawPattern.DiagonalDirection);
		}

		FPlane RevealPlane = FPlane(
			Math::Lerp(Start, End, RevealFraction),
			Normal
		);

		return RevealPlane;
	}

	void RequestDraw() override
	{
		if(State != ESketchbookDrawableState::NotDrawn)
			return;

		Super::RequestDraw();

		for(ASketchbookDrawableProp Prop : Props)
		{
			Prop.DrawableComp.SetState(State);
		}
	}

	FVector GetTravelToLocation(bool bErase) const override
	{
		FSketchbookDrawablePropGroupPattern Pattern = bErase ? ErasePattern : DrawPattern;
		return GetDiagonalStartLocation(Pattern.DiagonalDirection);
	}

	FVector GetTravelFromLocation(bool bErase) const override
	{
		FSketchbookDrawablePropGroupPattern Pattern = bErase ? ErasePattern : DrawPattern;
		return GetDiagonalEndLocation(Pattern.DiagonalDirection);
	}

	void StartBeingDrawn() override
	{
		ESketchbookDrawableState BeforeState = State;

		Super::StartBeingDrawn();

		for(ASketchbookDrawableProp Prop : Props)
		{
			Prop.DrawableComp.SetState(BeforeState);
			Prop.DrawableComp.StartBeingDrawn();
			Prop.DrawableComp.SetState(State);
		}

		if(bBeingReplaced)
			return;

		if(ReplacePropGroup.IsValid())
		{
			USketchbookDrawablePropGroupComponent ReplaceDrawable = ReplacePropGroup.Get().DrawableComp;
			ReplaceDrawable.bBeingReplaced = true;
			ReplacePropGroup.Get().DrawableComp.StartBeingErased();
			ReplaceDrawable.bBeingReplaced = false;
		}
	}

	void UpdateDrawnFraction(float Fraction, bool bErase, FPlane DrawPlane) override
	{
		ESketchbookDrawableState BeforeState = State;

		Super::UpdateDrawnFraction(Fraction, bErase, DrawPlane);

		for(ASketchbookDrawableProp Prop : Props)
		{
			if(Prop == nullptr)
				continue;
			
			Prop.DrawableComp.bInitializing = bInitializing;
			Prop.DrawableComp.SetState(BeforeState);

			Prop.DrawableComp.UpdateDrawnFraction(Fraction, bErase, DrawPlane);
			Prop.DrawableComp.SetState(State);
			Prop.DrawableComp.bInitializing = false;
		}

		if(bBeingReplaced)
			return;

		if(ReplacePropGroup.IsValid() && !bInitializing && !bErase)
		{
			USketchbookDrawablePropGroupComponent ReplaceDrawable = ReplacePropGroup.Get().DrawableComp;
			ReplaceDrawable.bBeingReplaced = true;
			ReplaceDrawable.UpdateDrawnFraction(1.0 - Fraction, true, FPlane(DrawPlane.Origin, -DrawPlane.Normal));
			ReplaceDrawable.bBeingReplaced = false;
		}
	}

	void FinishBeingDrawn() override
	{
		ESketchbookDrawableState BeforeState = State;
		Super::FinishBeingDrawn();
		
		for(ASketchbookDrawableProp Prop : Props)
		{
			if(Prop == nullptr)
				continue;
			
			Prop.DrawableComp.bInitializing = bInitializing;
			Prop.DrawableComp.SetState(BeforeState);
			Prop.DrawableComp.FinishBeingDrawn();
			Prop.DrawableComp.SetState(State);
			Prop.DrawableComp.bInitializing = false;
		}

		if(bBeingReplaced)
			return;

		if(ReplacePropGroup.IsValid())
		{
			USketchbookDrawablePropGroupComponent ReplaceDrawable = ReplacePropGroup.Get().DrawableComp;
			ReplaceDrawable.bBeingReplaced = true;
			ReplaceDrawable.FinishBeingErased();
			ReplaceDrawable.bBeingReplaced = false;
		}
	}

	void RequestErase() override
	{
		if(State != ESketchbookDrawableState::Drawn)
			return;

		Super::RequestErase();

		for(ASketchbookDrawableProp Prop : Props)
			Prop.DrawableComp.SetState(State);
	}

	void StartBeingErased() override
	{
		ESketchbookDrawableState BeforeState = State;
		Super::StartBeingErased();
		
		for(ASketchbookDrawableProp Prop : Props)
		{
			Prop.DrawableComp.SetState(BeforeState);
			Prop.DrawableComp.StartBeingErased();
			Prop.DrawableComp.SetState(State);
		}
	}

	void FinishBeingErased() override
	{
		ESketchbookDrawableState BeforeState = State;

		Super::FinishBeingErased();
		
		for(ASketchbookDrawableProp Prop : Props)
		{
			Prop.DrawableComp.SetState(BeforeState);
			Prop.DrawableComp.FinishBeingErased();
			Prop.DrawableComp.SetState(State);
		}
	}

	FVector GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection Direction) const
	{
		FVector BoundsOrigin;
		FVector BoundsExtents;
		GetWorldBounds(BoundsOrigin, BoundsExtents);
		
		switch(Direction)
		{
			case ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight:
				return BoundsOrigin + FVector(0, -BoundsExtents.Y, BoundsExtents.Z);

			case ESketchbookDrawablePropGroupDirection::TopRightToBottomLeft:
				return BoundsOrigin + FVector(0, BoundsExtents.Y, BoundsExtents.Z);

			case ESketchbookDrawablePropGroupDirection::BottomLeftToTopRight:
				return BoundsOrigin + FVector(0, -BoundsExtents.Y, -BoundsExtents.Z);

			case ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft:
				return BoundsOrigin + FVector(0, BoundsExtents.Y, -BoundsExtents.Z);
		}
	}

	FVector GetDiagonalEndLocation(ESketchbookDrawablePropGroupDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight:
				return GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft);

			case ESketchbookDrawablePropGroupDirection::TopRightToBottomLeft:
				return GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::BottomLeftToTopRight);

			case ESketchbookDrawablePropGroupDirection::BottomLeftToTopRight:
				return GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::TopRightToBottomLeft);

			case ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft:
				return GetDiagonalStartLocation(ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight);
		}
	}

	void GetOrthogonalVectors(ESketchbookDrawablePropGroupDirection Direction, FVector&out First, FVector&out Second)
	{
		switch(Direction)
		{
			case ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight:
			case ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft:
			{
				First = FVector(0, 1, 1).GetSafeNormal();
				Second = -First;
				break;
			}

			case ESketchbookDrawablePropGroupDirection::BottomLeftToTopRight:
			case ESketchbookDrawablePropGroupDirection::TopRightToBottomLeft:
			{
				First = FVector(0, -1, 1).GetSafeNormal();
				Second = -First;
				break;
			}

			default:
				break;
		}
	}

	FVector GetDrawNormal(ESketchbookDrawablePropGroupDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawablePropGroupDirection::TopLeftToBottomRight:
				return FVector(0, 1, -1).GetSafeNormal();

			case ESketchbookDrawablePropGroupDirection::TopRightToBottomLeft:
				return FVector(0, -1, -1).GetSafeNormal();

			case ESketchbookDrawablePropGroupDirection::BottomLeftToTopRight:
				return FVector(0, 1, 1).GetSafeNormal();

			case ESketchbookDrawablePropGroupDirection::BottomRightToTopLeft:
				return FVector(0, -1, 1).GetSafeNormal();
		}
	}

#if EDITOR
	void CalculateEditorBounds(FVector&out OutOrigin, FVector&out OutExtents) const override
	{
		if(Props.IsEmpty() || Props[0] == nullptr)
		{
			OutOrigin = FVector::ZeroVector;
			OutExtents = FVector::ZeroVector;
			return;
		}

		Props[0].DrawableComp.FitBounds();

		FVector Min, Max;
		Props[0].DrawableComp.GetWorldMinMax(false, Min, Max);

		FBox GroupBounds = FBox(Min, Max);

		for(auto Prop : Props)
		{
			if(Prop == nullptr)
				continue;

			Prop.DrawableComp.FitBounds();
			Prop.DrawableComp.GetWorldMinMax(false, Min, Max);
			FBox PropBounds = FBox(Min, Max);
			GroupBounds += PropBounds;
		}

		OutOrigin = GroupBounds.Center;
		OutExtents = GroupBounds.Extent;
	}
#endif
};

#if EDITOR
class USketchbookDrawablePropGroupVisualizer : USketchbookDrawableVisualizer
{
	default VisualizedClass = USketchbookDrawablePropGroupComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);

		auto Drawable = Cast<USketchbookDrawablePropGroupComponent>(Component);
		if(Drawable == nullptr)
			return;

		if(Drawable.Props.IsEmpty())
		{
			DrawWorldString("No props assigned!", Drawable.Owner.ActorLocation, FLinearColor::Red, 2, bCenterText = true);
			return;
		}

		FVector BoundsOrigin;
		FVector BoundsExtents;
		Drawable.GetWorldBounds(BoundsOrigin, BoundsExtents);

		DrawWireBox(BoundsOrigin, BoundsExtents, FQuat::Identity, FLinearColor::Yellow, 3);

		FVector StartLocation;
		FVector EndLocation;

		ESketchbookDrawablePropGroupDirection Direction = Drawable.DrawPattern.DiagonalDirection;
		StartLocation = Drawable.GetDiagonalStartLocation(Direction);
		EndLocation = Drawable.GetDiagonalEndLocation(Direction);

		DrawPoint(StartLocation, FLinearColor::Green, 20);
		DrawPoint(EndLocation, FLinearColor::Red, 20);
		DrawLine(StartLocation, EndLocation, FLinearColor::Black, 1);

		FVector Origin, Extents;
		// PropGroup.GetWorldBounds(Origin, Extents);
		// DrawWireBox(Origin, Extents, FQuat::Identity, Sketchbook::Editor::PropGroupColor, 20);

		for(auto Prop : Drawable.Props)
		{
			if(Prop == nullptr)
				continue;

			Prop.DrawableComp.GetWorldBounds(false, Origin, Extents);

			//DrawWorldString(f"{Origin=} {Extents=}", Origin, Sketchbook::Editor::PropGroupColor, bCenterText = true);
			DrawWireBox(Origin, Extents, FQuat::Identity, Sketchbook::Editor::PropGroupColor, Sketchbook::Editor::BoundsThickness);
			DrawArrow(Drawable.Owner.ActorLocation, Origin, Sketchbook::Editor::PropGroupColor, 1, 1, true);
		}
	}
}
#endif