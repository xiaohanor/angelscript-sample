event void FGravityBikeSplineActorOnBecomeCurrentSpline();
event void FGravityBikeSplineActorOnLoseBeingCurrentSpline();

UCLASS(NotBlueprintable)
class AGravityBikeSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent SplineComp;
#if EDITOR
	default SplineComp.EditingSettings.SplineColor = FLinearColor::Green;
	default SplineComp.EditingSettings.bEnableVisualizeScale = true;
	default SplineComp.EditingSettings.VisualizeScale = 1;
#endif

	UPROPERTY(DefaultComponent)
	UGravityBikeSplineCameraLookSplineComponent CameraLookSplineComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;

	UPROPERTY(EditInstanceOnly)
	bool bUseForGravityDirection = true;

	UPROPERTY(EditInstanceOnly)
	bool bNoTurnReferenceDelay = false;

	FGravityBikeSplineActorOnBecomeCurrentSpline OnBecomeCurrentSpline;
	FGravityBikeSplineActorOnLoseBeingCurrentSpline OnLoseBeingCurrentSpline;
};

#if EDITOR
class UGravityBikeSplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AGravityBikeSplineActor))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Gravity Bike Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;

		{
			FHazeContextOption AddActivateEnemy;
			AddActivateEnemy.DelegateParam = n"AddActivateEnemyTrigger";
			AddActivateEnemy.Label = "Add Activate Enemy Trigger";
			AddActivateEnemy.Icon = n"Icons.Plus";
			AddActivateEnemy.Tooltip = "";
			Menu.AddOption(AddActivateEnemy, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddActivateEnemyTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineActivateEnemiesTriggerComponent);
		}
	}
};
#endif