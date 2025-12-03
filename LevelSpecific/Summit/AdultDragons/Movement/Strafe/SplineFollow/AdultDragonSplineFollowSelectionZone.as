
class AAdultDragonSplineFollowSelectionZone : APlayerTrigger
{
	UPROPERTY(EditInstanceOnly, Category = "AdultDragonFollowSelectionZone")
	TArray<ASplineActor> AutoSelectableSplines;

	UPROPERTY(EditInstanceOnly, Category = "AdultDragonFollowSelectionZone")
	float SplineSwitchBlendTime = 3.0;
	
	protected void TriggerOnPlayerEnter(AHazePlayerCharacter Player) override
	{
		if (Player.IsPlayerDeadOrRespawning())
			return;
		
		auto Manager = UAdultDragonSplineFollowManagerComponent::Get(Player);
		if (Manager != nullptr)
		{
			Manager.AddSplinesToConsider(this, AutoSelectableSplines);
			Manager.SelectionZone = this;
		}

		Super::TriggerOnPlayerEnter(Player);
	}

	protected void TriggerOnPlayerLeave(AHazePlayerCharacter Player) override
	{
		auto Manager = UAdultDragonSplineFollowManagerComponent::Get(Player);
		if (Manager != nullptr)
		{
			Manager.RemoveSplinesToConsider(this);
		}

		Super::TriggerOnPlayerLeave(Player);
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "AdultDragonFollowSelectionZone")
	void FetchSplinesInsideExtents()
	{
		FScopedTransaction Transaction("Fetch Splines Inside Extents");
		Modify();
		TArray<AActor> Actors = Editor::GetAllEditorWorldActorsOfClass(AActor);
		for (auto Actor : Actors)
		{
			auto FollowSplineComp = USummitAdultDragonSplineFollowComponent::Get(Actor);
			if (FollowSplineComp == nullptr)
				continue;

			auto SplineComp = UHazeSplineComponent::Get(Actor);

			auto ClosestLocation = SplineComp.GetClosestSplineWorldLocationToWorldLocation(ActorLocation);
			auto ToLocation = ClosestLocation - ActorLocation;
			if (ToLocation.SizeSquared() < BrushComponent.BoundsRadius * BrushComponent.BoundsRadius)
			{
				AutoSelectableSplines.AddUnique(Cast<ASplineActor>(SplineComp.Owner));
			}

		}
	}
#endif
};

#if EDITOR
class UAdultDragonSplineFollowSelectionZoneContextMenuExtension : UHazeSplineContextMenuExtension
{
	FName SplineFollowSelectionZoneContextName = n"AddSplineFollowSelectionZone";

	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.World.Name.PlainNameString.Contains("Summit", ESearchCase::IgnoreCase, ESearchDir::FromStart))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Summit - AdultDragons";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddSelectionZone;
			AddSelectionZone.DelegateParam = SplineFollowSelectionZoneContextName;
			AddSelectionZone.Label = "Add AdultDragon SplineFollow Selection Zone";
			AddSelectionZone.Icon = n"Icons.Plus";
			AddSelectionZone.Tooltip = "Add a volume where adultdragons can change follow splines.";
			Menu.AddOption(AddSelectionZone, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == SplineFollowSelectionZoneContextName)
		{
			FScopedTransaction Transaction("Spawn SplineFollowSelectionZone");
			FAngelscriptGameThreadScopeWorldContext WorldScope(Spline.Owner);

			auto AddedZone = SpawnActor(AAdultDragonSplineFollowSelectionZone);
			FTransform Transform = Spline.GetWorldTransformAtSplineDistance(MenuClickedDistance);
			Transform.Scale3D = FVector::OneVector;
			AddedZone.SetActorTransform(Transform);
			Shape::CreateBrush(AddedZone, FHazeShapeSettings::MakeBox(FVector(100,100,100)));
			Editor::SelectActor(AddedZone);
		}
	}
}
#endif