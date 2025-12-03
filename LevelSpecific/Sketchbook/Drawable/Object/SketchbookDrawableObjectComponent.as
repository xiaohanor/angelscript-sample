enum ESketchbookDrawableObjectDirection
{
	TopLeftToBottomRight,
	TopRightToBottomLeft,
	BottomLeftToTopRight,
	BottomRightToTopLeft,
};

enum ESketchbookDrawableObjectSplineDirection
{
	Forward,
	Backward,
};

struct FSketchbookDrawableObjectPattern
{
	UPROPERTY(EditAnywhere)
	bool bPickClosestDirection = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "!bPickClosestDirection", EditConditionHides))
	ESketchbookDrawableObjectDirection DiagonalDirection = ESketchbookDrawableObjectDirection::TopLeftToBottomRight;

	/**
	 * Will be lerped from Min to Max over the pattern duration.
	 */
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "Type == ESketchbookDrawableObjectPatternType::Diagonal", EditConditionHides))
	FHazeRange DiagonalWiggleFrequency = FHazeRange(10, 20);
};

struct FSketchBookRevealOverrideMaterial {
	UPROPERTY(EditAnywhere)
	UMaterialInterface Material;

	UPROPERTY(EditAnywhere)
	int MaterialIndex = -1;
};

UCLASS(NotBlueprintable)
class USketchbookDrawableObjectComponent : USketchbookDrawableComponent
{	
	UPROPERTY(EditAnywhere, Category = "Drawable Object|Material")
	UMaterialInterface SketchbookMaterial;

	/** Used to override a single material slot */
	UPROPERTY(EditAnywhere, Category = "Drawable Object|Material")
	TArray<FSketchBookRevealOverrideMaterial> OverrideMaterials;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds")
	bool bAutomaticBounds = false;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds", Meta = (EditCondition = "!bAutomaticBounds"))
	FVector2D Origin;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds", Meta = (EditCondition = "!bAutomaticBounds"))
	FVector2D Extents;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds")
	bool bUseSeparateEraseBounds = false;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds", Meta = (EditCondition = "bUseSeparateEraseBounds"))
	FVector2D EraseOrigin;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Bounds", Meta = (EditCondition = "bUseSeparateEraseBounds"))
	FVector2D EraseExtents;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Draw")
	float DrawTime = 0.5;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Draw")
	FSketchbookDrawableObjectPattern DrawPattern;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Erase")
	float EraseTime = 1.0;

	UPROPERTY(EditAnywhere, Category = "Drawable Object|Erase")
	FSketchbookDrawableObjectPattern ErasePattern;
	default ErasePattern.bPickClosestDirection = true;

	private TArray<UMeshComponent> MeshComponents;

#if EDITOR
	UFUNCTION(BlueprintOverride, Meta = (NoSuperCall))
	void OnActorOwnerModifiedInEditor()
	{
		auto Prop = Cast<ASketchbookDrawableProp>(Owner);
		if(Prop != nullptr)
		{
			ASketchbookDrawablePropGroup Group = Sketchbook::Editor::FindGroupForProp(Prop);
			if(Group != nullptr)
			{
				// We are owned by a group! UpdateInEditor will be called from there instead
				return;
			}
		}

		UpdateInEditor(false);
	}

	void UpdateInEditor(bool bForce) override
	{
		Super::UpdateInEditor(bForce);
		
		if(SketchbookMaterial == nullptr)
		{
			SketchbookMaterial = Cast<UMaterialInterface>(Editor::LoadAsset(n"/Script/Engine.Material'/Game/LevelSpecific/Sketchbook/Shaders/Reveal/M_SketchBook_MeshReveal.M_SketchBook_MeshReveal'"));
			check(SketchbookMaterial != nullptr, "Failed to load M_SketchBook_MeshReveal. Has it been moved?");
		}

		for(auto MeshComp : MeshComponents)
		{
			for(const FName& SlotName : MeshComp.MaterialSlotNames)
				MeshComp.SetMaterialByName(SlotName, SketchbookMaterial);
		}

		// Apply override materials
		if(!OverrideMaterials.IsEmpty())
		{
			for(auto MeshComp : MeshComponents)
			{
				for(auto OverrideMaterial : OverrideMaterials)
					MeshComp.SetMaterial(OverrideMaterial.MaterialIndex, OverrideMaterial.Material);
			}
		}

		if(Extents.IsNearlyZero() || bAutomaticBounds)
			FitBounds();

		MeshComponents.Reset();
		Owner.GetComponentsByClass(MeshComponents);

		if(MeshComponents.IsEmpty())
			return;

		const FPlane RevealPlane = CalculateRevealPlane(
			PreviewFraction,
			bPreviewErase
		);
		
		for(auto MeshComp : MeshComponents)
		{
			MeshComp.SetScalarParameterValueOnMaterials(
				n"RevealFraction",
				PreviewFraction
			);

			MeshComp.SetColorParameterValueOnMaterials(
				n"RevealPlane",
				FLinearColor(
					RevealPlane.X,
					RevealPlane.Y,
					RevealPlane.Z,
					RevealPlane.W
				)
			);

			//Debug::DrawDebugString(FVector(Owner.ActorLocation.X, Min.X, Min.Y), f"Min: {Min}", Duration = 5);
			//Debug::DrawDebugString(FVector(Owner.ActorLocation.X, Max.X, Max.Y), f"Max: {Max}", Duration = 5);
		}
	}

	UFUNCTION(CallInEditor, Category = "Drawable Object")
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
		MeshComponents.Reset();
		Owner.GetComponentsByClass(MeshComponents);

		Super::BeginPlay();
	}

	void PrepareTravelTo(bool bErase, FVector TravelFromLocation) override
	{
		Super::PrepareTravelTo(bErase, TravelFromLocation);

		if(bErase && ErasePattern.bPickClosestDirection)
		{
			ErasePattern.DiagonalDirection = GetClosestDiagonalDirectionToLocation(bErase, TravelFromLocation);
		}
		else if(!bErase && DrawPattern.bPickClosestDirection)
		{
			DrawPattern.DiagonalDirection = GetClosestDiagonalDirectionToLocation(bErase, TravelFromLocation);
		}
	}

	void UpdateDrawnFraction(float Fraction, bool bErase, FPlane DrawPlane) override
	{
		Super::UpdateDrawnFraction(Fraction, bErase, DrawPlane);
		
		for(auto MeshComp : MeshComponents)
		{
			MeshComp.SetScalarParameterValueOnMaterials(
				n"RevealFraction",
				Fraction
			);

			MeshComp.SetColorParameterValueOnMaterials(
				n"RevealPlane",
				FLinearColor(
					DrawPlane.X,
					DrawPlane.Y,
					DrawPlane.Z,
					DrawPlane.W
				)
			);
		}
	}

	FVector GetTravelToLocation(bool bErase) const override
	{
		FSketchbookDrawableObjectPattern Pattern = bErase ? ErasePattern : DrawPattern;
		return GetDiagonalStartLocation(bErase, Pattern.DiagonalDirection);
	}

	FVector GetTravelFromLocation(bool bErase) const override
	{
		FSketchbookDrawableObjectPattern Pattern = bErase ? ErasePattern : DrawPattern;
		return GetDiagonalEndLocation(bErase, Pattern.DiagonalDirection);
	}

	ESketchbookDrawableObjectDirection GetClosestDiagonalDirectionToLocation(bool bErase, FVector Location) const
	{
		TArray<FVector> Locations;
		Locations.Add(GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::TopLeftToBottomRight));
		Locations.Add(GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::TopRightToBottomLeft));
		Locations.Add(GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::BottomLeftToTopRight));
		Locations.Add(GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::BottomRightToTopLeft));

		int ClosestIndex = -1;
		float ClosestDistance = BIG_NUMBER;

		for(int i = 0; i < Locations.Num(); i++)
		{
			float Distance = Location.Distance(Locations[i]);
			if(Distance < ClosestDistance)
			{
				ClosestIndex = i;
				ClosestDistance = Distance;
			}
		}

		if(ClosestIndex < 0)
			return ESketchbookDrawableObjectDirection::TopLeftToBottomRight;

		return ESketchbookDrawableObjectDirection(ClosestIndex);
	}

	FVector GetDiagonalStartLocation(bool bErase, ESketchbookDrawableObjectDirection Direction) const
	{
		FVector BoundsOrigin;
		FVector BoundsExtents;
		GetWorldBounds(bErase, BoundsOrigin, BoundsExtents);
		
		switch(Direction)
		{
			case ESketchbookDrawableObjectDirection::TopLeftToBottomRight:
				return BoundsOrigin + FVector(0, -BoundsExtents.Y, BoundsExtents.Z);

			case ESketchbookDrawableObjectDirection::TopRightToBottomLeft:
				return BoundsOrigin + FVector(0, BoundsExtents.Y, BoundsExtents.Z);

			case ESketchbookDrawableObjectDirection::BottomLeftToTopRight:
				return BoundsOrigin + FVector(0, -BoundsExtents.Y, -BoundsExtents.Z);

			case ESketchbookDrawableObjectDirection::BottomRightToTopLeft:
				return BoundsOrigin + FVector(0, BoundsExtents.Y, -BoundsExtents.Z);
		}
	}

	FVector GetDiagonalEndLocation(bool bErase, ESketchbookDrawableObjectDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawableObjectDirection::TopLeftToBottomRight:
				return GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::BottomRightToTopLeft);

			case ESketchbookDrawableObjectDirection::TopRightToBottomLeft:
				return GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::BottomLeftToTopRight);

			case ESketchbookDrawableObjectDirection::BottomLeftToTopRight:
				return GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::TopRightToBottomLeft);

			case ESketchbookDrawableObjectDirection::BottomRightToTopLeft:
				return GetDiagonalStartLocation(bErase, ESketchbookDrawableObjectDirection::TopLeftToBottomRight);
		}
	}

	FVector2D GetBoundsOrigin(bool bErase) const
	{
		if(bUseSeparateEraseBounds && bErase)
			return EraseOrigin;
		else
			return Origin;
	}

	FVector2D GetBoundsExtents(bool bErase) const
	{
		if(bUseSeparateEraseBounds && bErase)
			return EraseExtents;
		else
			return Extents;
	}

	FVector GetWorldOrigin(bool bErase) const
	{
		const FVector2D BoundsOrigin = GetBoundsOrigin(bErase);
		return FVector(0, Owner.ActorLocation.Y, Owner.ActorLocation.Z) + FVector(0, BoundsOrigin.X, BoundsOrigin.Y);
	}

	void GetWorldBounds(bool bErase, FVector&out OutOrigin, FVector&out OutExtents) const
	{
		OutOrigin = GetWorldOrigin(bErase);

		const FVector2D BoundsExtents = GetBoundsExtents(bErase);
		OutExtents = FVector(0, BoundsExtents.X, BoundsExtents.Y);
	}

	void GetWorldMinMax(bool bErase, FVector&out OutMin, FVector&out OutMax) const
	{
		FVector WorldOrigin, WorldExtents;
		GetWorldBounds(bErase, WorldOrigin, WorldExtents);
		
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
			Start = GetDiagonalEndLocation(bErase, ErasePattern.DiagonalDirection);
			End = GetDiagonalStartLocation(bErase, ErasePattern.DiagonalDirection);
			Normal = -GetDrawNormal(ErasePattern.DiagonalDirection);
		}
		else
		{
			Start = GetDiagonalStartLocation(bErase, DrawPattern.DiagonalDirection);
			End = GetDiagonalEndLocation(bErase, DrawPattern.DiagonalDirection);
			Normal = GetDrawNormal(DrawPattern.DiagonalDirection);
		}

		FPlane RevealPlane = FPlane(
			Math::Lerp(Start, End, RevealFraction),
			Normal
		);

		return RevealPlane;
	}

	void GetOrthogonalVectors(ESketchbookDrawableObjectDirection Direction, FVector&out First, FVector&out Second) const
	{
		switch(Direction)
		{
			case ESketchbookDrawableObjectDirection::TopLeftToBottomRight:
			case ESketchbookDrawableObjectDirection::BottomRightToTopLeft:
			{
				First = FVector(0, 1, 1).GetSafeNormal();
				Second = -First;
				break;
			}

			case ESketchbookDrawableObjectDirection::BottomLeftToTopRight:
			case ESketchbookDrawableObjectDirection::TopRightToBottomLeft:
			{
				First = FVector(0, -1, 1).GetSafeNormal();
				Second = -First;
				break;
			}

			default:
				break;
		}
	}

	FVector GetDrawNormal(ESketchbookDrawableObjectDirection Direction) const
	{
		switch(Direction)
		{
			case ESketchbookDrawableObjectDirection::TopLeftToBottomRight:
				return FVector(0, 1, -1).GetSafeNormal();

			case ESketchbookDrawableObjectDirection::TopRightToBottomLeft:
				return FVector(0, -1, -1).GetSafeNormal();

			case ESketchbookDrawableObjectDirection::BottomLeftToTopRight:
				return FVector(0, 1, 1).GetSafeNormal();

			case ESketchbookDrawableObjectDirection::BottomRightToTopLeft:
				return FVector(0, -1, 1).GetSafeNormal();
		}
	}

#if EDITOR
	void CalculateEditorBounds(FVector&out OutOrigin, FVector&out OutExtents) const override
	{
		Owner.GetActorBounds(false, OutOrigin, OutExtents);
	}

	UFUNCTION(CallInEditor, Category = "Convert")
	private void ConvertToDrawablePropActor()
	{
		FScopedTransaction("ConvertToDrawablePropActor");
		Owner.Modify();

		auto DrawableProp = Sketchbook::Editor::ReplaceActorWithDrawableProp(Owner);
		if(DrawableProp == nullptr)
			return;

		Editor::SelectActor(DrawableProp);
	}
#endif
};

namespace Sketchbook
{
	FVector GetRayRectangleIntersection(FVector TopLeft, FVector BottomRight, FVector RayOrigin, FVector RayDirection)
	{
		const FPlane TopPlane = FPlane(BottomRight, FVector::UpVector);
		const FPlane RightPlane = FPlane(BottomRight, FVector::LeftVector);
		const FPlane BottomPlane = FPlane(TopLeft, FVector::DownVector);
		const FPlane LeftPlane = FPlane(TopLeft, FVector::RightVector);

		TArray<FPlane> Planes;
		Planes.Add(TopPlane);
		Planes.Add(RightPlane);
		Planes.Add(BottomPlane);
		Planes.Add(LeftPlane);

		for(int i = Planes.Num() - 1; i >= 0; i--)
		{
			if(Planes[i].Normal.DotProduct(RayDirection) > 0)
			{
				Planes.RemoveAt(i);
				continue;
			}
		}

		if(Planes.Num() == 1)
		{
			return Math::RayPlaneIntersection(RayOrigin, RayDirection, Planes[0]);
		}
		else if(Planes.Num() == 2)
		{
			FVector FirstHit = Math::RayPlaneIntersection(RayOrigin, RayDirection, Planes[0]);
			FVector SecondHit = Math::RayPlaneIntersection(RayOrigin, RayDirection, Planes[1]);

			if(FirstHit.Distance(RayOrigin) < SecondHit.Distance(RayOrigin))
				return FirstHit;
			else
				return SecondHit;
		}

		check(false, "This should be impossible!");
		return RayOrigin;
	}
};

#if EDITOR
class USketchbookDrawableObjectDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = USketchbookDrawableObjectComponent;

	UHazeImmediateDrawer MainDrawer;
	bool bCanConvert;
	
	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		auto Drawable = Cast<USketchbookDrawableObjectComponent>(CustomizedObject);
		if(Drawable == nullptr || Drawable.Owner == nullptr)
			return;

		MainDrawer = AddImmediateRow(n"Convert");
		if(MainDrawer == nullptr)
			return;

		bCanConvert = Sketchbook::Editor::CanConvertActorToDrawableProp(Drawable.Owner);
		
		if(!bCanConvert)
		{
			HideCategory(n"Convert");
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(MainDrawer == nullptr)
			return;

		if(!MainDrawer.IsVisible())
			return;

		if(bCanConvert)
		{
			auto WarningSection = MainDrawer.BeginVerticalBox().Section().Color(FLinearColor::Yellow);
				
			WarningSection
				.Text("⚠ The actor is a HazeProp or StaticMeshActor! Actor needs to be converted! ⚠")
				.Color(FLinearColor::Black)
				.AutoWrapText()
			;
		}
	}
}
#endif

#if EDITOR
class USketchbookDrawableObjectVisualizer : USketchbookDrawableVisualizer
{
	default VisualizedClass = USketchbookDrawableObjectComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		Super::VisualizeComponent(Component);
		
		auto Drawable = Cast<USketchbookDrawableObjectComponent>(Component);
		if(Drawable == nullptr)
			return;

		FVector BoundsOrigin;
		FVector BoundsExtents;
		Drawable.GetWorldBounds(false, BoundsOrigin, BoundsExtents);

		DrawWireBox(BoundsOrigin, BoundsExtents, FQuat::Identity, FLinearColor::Yellow, 3);

		if(Drawable.bUseSeparateEraseBounds)
		{
			Drawable.GetWorldBounds(true, BoundsOrigin, BoundsExtents);
			DrawWireBox(BoundsOrigin, BoundsExtents, FQuat::Identity, FLinearColor::Red, 3);
		}

		const ESketchbookDrawableObjectDirection Direction = Drawable.DrawPattern.DiagonalDirection;
		const FVector StartLocation = Drawable.GetDiagonalStartLocation(false, Direction);
		const FVector EndLocation = Drawable.GetDiagonalEndLocation(false, Direction);

		DrawPoint(StartLocation, FLinearColor::Green, 20);
		DrawPoint(EndLocation, FLinearColor::Red, 20);
		DrawLine(StartLocation, EndLocation, FLinearColor::Black, 1);
	}
};
#endif