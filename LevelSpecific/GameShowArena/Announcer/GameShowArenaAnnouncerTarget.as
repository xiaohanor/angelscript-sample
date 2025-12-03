class AGameShowArenaAnnouncerTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;
	default BillboardComp.SpriteName = "Scenepoint";
	default BillboardComp.WorldScale3D = FVector(8);
	#endif

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	UPROPERTY(EditAnywhere)
	float SplineDistance;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(SplineActor.Spline.GetWorldLocationAtSplineDistance(SplineDistance), 150, 12);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineActor == nullptr)
			return;

		auto SplinePos = SplineActor.Spline.GetSplinePositionAtSplineDistance(SplineDistance);
		SetActorLocationAndRotation(SplinePos.WorldLocation, SplinePos.WorldRotation);
		Editor::SelectActor(this);
	}
};

#if EDITOR
class UGameShowArenaSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if (!Spline.World.Name.PlainNameString.Contains("GameShow", ESearchCase::IgnoreCase, ESearchDir::FromStart))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "GameShow";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddAnnouncerTarget;
			AddAnnouncerTarget.DelegateParam = n"AddAnnouncerTarget";
			AddAnnouncerTarget.Label = "Add Announcer Target";
			AddAnnouncerTarget.Icon = n"Icons.Plus";
			AddAnnouncerTarget.Tooltip = "Add a target for the announcer.";
			Menu.AddOption(AddAnnouncerTarget, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
									UHazeSplineSelection Selection, float MenuClickedDistance,
									int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddAnnouncerTarget")
		{
			FScopedTransaction Transaction("Spawn Announcer Target");
			FAngelscriptGameThreadScopeWorldContext WorldContext(Spline.Owner);
			auto SplinePos = Spline.GetSplinePositionAtSplineDistance(MenuClickedDistance);
			auto Target = SpawnActor(AGameShowArenaAnnouncerTarget, SplinePos.WorldLocation, SplinePos.WorldRotation.Rotator());
			Target.SplineDistance = MenuClickedDistance;
			Target.SplineActor = Cast<ASplineActor>(Spline.Owner);
			Editor::SelectActor(Target);
			Spline.Owner.Modify();
		}
	}
};
#endif