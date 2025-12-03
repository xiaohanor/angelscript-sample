event void FGravityBikeSplineEnemyLevelEvent(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, FName EventTag, UGravityBikeSplineEnemyLevelEventTriggerComponent Trigger, bool bIsTeleport);

UCLASS(NotBlueprintable)
class AGravityBikeSplineEnemySpline : ASplineActor
{
	/**
	 * The spline up vector can be hard to define. If needed, we can toggle this to use the GravityBikes current spline up instead.
	 */
	UPROPERTY(EditInstanceOnly)
	bool bUseGravityBikeSplineUp = false;

	UPROPERTY()
	FGravityBikeSplineEnemyLevelEvent OnEnterLevelEventTrigger;

	FVector GetUpAtSplineDistance(float DistanceAlongSpline) const
	{
		if(bUseGravityBikeSplineUp)
		{
			auto GravityBikeSpline = GravityBikeSpline::GetGravityBikeSpline();
			if(GravityBikeSpline != nullptr)
			{
				const FVector SplineLocation = Spline.GetWorldLocationAtSplineDistance(DistanceAlongSpline);
				const float OtherSplineDistance = GravityBikeSpline.SplineComp.GetClosestSplineDistanceToWorldLocation(SplineLocation);
				return GravityBikeSpline.SplineComp.GetWorldRotationAtSplineDistance(OtherSplineDistance).UpVector;
			}
		}

		return Spline.GetWorldRotationAtSplineDistance(DistanceAlongSpline).UpVector;
	}

#if EDITOR
	UFUNCTION(CallInEditor, Category = "EnemySpline")
	private void SelectAllEnemiesOnSpline()
	{
		TArray<AHazeActor> AllActors = Editor::GetAllEditorWorldActorsOfClass(AHazeActor);

		TArray<AActor> ActorsToSelect;
		for(auto Actor : AllActors)
		{
			auto EnemyMoveComp = UGravityBikeSplineEnemyMovementComponent::Get(Actor);
			if(EnemyMoveComp == nullptr)
				continue;

			if(EnemyMoveComp.GetSplineComp() == Spline)
				ActorsToSelect.Add(Actor);
		}

		Editor::SelectActors(ActorsToSelect);
	}
#endif
};

#if EDITOR
class UGravityBikeEnemySplineContextMenuExtension : UHazeSplineContextMenuExtension
{
	bool IsValidForContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline,
							   UHazeSplineSelection Selection, int ClickedPoint, float ClickedDistance) const override
	{
		if(!Spline.Owner.IsA(AGravityBikeSplineEnemySpline))
			return false;

		return true;
	}

	FString GetSectionName() const override
	{
		return "Gravity Bike Enemy Spline";
	}

	void GenerateContextMenu(FHazeContextMenu& Menu, UHazeSplineComponent Spline, FHazeContextDelegate MenuDelegate, UHazeSplineSelection Selection, int ClickedPoint,
							 float ClickedDistance) override
	{
		if (ClickedDistance < 0.0)
			return;
		
		{
			FHazeContextOption AddRifleTrigger;
			AddRifleTrigger.DelegateParam = n"AddRifleTrigger";
			AddRifleTrigger.Label = "Add Rifle Trigger";
			AddRifleTrigger.Icon = n"Icons.Plus";
			AddRifleTrigger.Tooltip = "";
			Menu.AddOption(AddRifleTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddMissileTrigger;
			AddMissileTrigger.DelegateParam = n"AddMissileTrigger";
			AddMissileTrigger.Label = "Add Missile Trigger";
			AddMissileTrigger.Icon = n"Icons.Plus";
			AddMissileTrigger.Tooltip = "";
			Menu.AddOption(AddMissileTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddLeadDistanceTrigger;
			AddLeadDistanceTrigger.DelegateParam = n"AddLeadDistanceTrigger";
			AddLeadDistanceTrigger.Label = "Add Lead Distance Trigger";
			AddLeadDistanceTrigger.Icon = n"Icons.Plus";
			AddLeadDistanceTrigger.Tooltip = "";
			Menu.AddOption(AddLeadDistanceTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddLevelEventTrigger;
			AddLevelEventTrigger.DelegateParam = n"AddLevelEventTrigger";
			AddLevelEventTrigger.Label = "Add Level Event Trigger";
			AddLevelEventTrigger.Icon = n"Icons.Plus";
			AddLevelEventTrigger.Tooltip = "";
			Menu.AddOption(AddLevelEventTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddNoCollisionTrigger;
			AddNoCollisionTrigger.DelegateParam = n"AddNoCollisionTrigger";
			AddNoCollisionTrigger.Label = "Add No Collision Trigger";
			AddNoCollisionTrigger.Icon = n"Icons.Plus";
			AddNoCollisionTrigger.Tooltip = "";
			Menu.AddOption(AddNoCollisionTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddDropBikeTrigger;
			AddDropBikeTrigger.DelegateParam = n"AddDropBikeTrigger";
			AddDropBikeTrigger.Label = "Add Drop Bike Trigger";
			AddDropBikeTrigger.Icon = n"Icons.Plus";
			AddDropBikeTrigger.Tooltip = "";
			Menu.AddOption(AddDropBikeTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddFacePlayerTrigger;
			AddFacePlayerTrigger.DelegateParam = n"AddFacePlayerTrigger";
			AddFacePlayerTrigger.Label = "Add Face Player Trigger";
			AddFacePlayerTrigger.Icon = n"Icons.Plus";
			AddFacePlayerTrigger.Tooltip = "";
			Menu.AddOption(AddFacePlayerTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddForceSpeedTrigger;
			AddForceSpeedTrigger.DelegateParam = n"AddForceSpeedTrigger";
			AddForceSpeedTrigger.Label = "Add Force Speed Trigger";
			AddForceSpeedTrigger.Icon = n"Icons.Plus";
			AddForceSpeedTrigger.Tooltip = "";
			Menu.AddOption(AddForceSpeedTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddBlockRespawnTrigger;
			AddBlockRespawnTrigger.DelegateParam = n"AddBlockRespawnTrigger";
			AddBlockRespawnTrigger.Label = "Add Block Respawn Trigger";
			AddBlockRespawnTrigger.Icon = n"Icons.Plus";
			AddBlockRespawnTrigger.Tooltip = "";
			Menu.AddOption(AddBlockRespawnTrigger, MenuDelegate);
		}

		{
			FHazeContextOption AddOpenHatchTrigger;
			AddOpenHatchTrigger.DelegateParam = n"AddOpenHatchTrigger";
			AddOpenHatchTrigger.Label = "Add Open Hatch Trigger";
			AddOpenHatchTrigger.Icon = n"Icons.Plus";
			AddOpenHatchTrigger.Tooltip = "";
			Menu.AddOption(AddOpenHatchTrigger, MenuDelegate);
		}
	}

	void HandleContextOptionClicked(FHazeContextOption Option, UHazeSplineComponent Spline,
	                                UHazeSplineSelection Selection, float MenuClickedDistance,
	                                int MenuClickedPoint) override
	{
		const FName OptionName = Option.DelegateParam;

		if (OptionName == n"AddRifleTrigger")
		{
			auto Component = AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyFireTriggerComponent);
			auto FireTriggerComp = Cast<UGravityBikeSplineEnemyFireTriggerComponent>(Component);
			FireTriggerComp.FireType = EGravityBikeSplineEnemyFireType::Rifle;
		}
		else if (OptionName == n"AddMissileTrigger")
		{
			auto Component = AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyFireTriggerComponent);
			auto FireTriggerComp = Cast<UGravityBikeSplineEnemyFireTriggerComponent>(Component);
			FireTriggerComp.FireType = EGravityBikeSplineEnemyFireType::Missile;
		}
		else if (OptionName == n"AddLeadDistanceTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyLeadDistanceTriggerComponent);

		}
		else if (OptionName == n"AddLevelEventTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyLevelEventTriggerComponent);

		}
		else if (OptionName == n"AddNoCollisionTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyNoCollisionTriggerComponent);
		}
		else if (OptionName == n"AddDropBikeTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineAttackShipDropBikeTriggerComponent);
		}
		else if (OptionName == n"AddFacePlayerTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineAttackShipFacePlayerTriggerComponent);
		}
		else if (OptionName == n"AddForceSpeedTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyForceSpeedTriggerComponent);
		}
		else if (OptionName == n"AddBlockRespawnTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineEnemyBlockRespawnTriggerComponent);
		}
		else if (OptionName == n"AddOpenHatchTrigger")
		{
			AddComponentToSpline(Spline, MenuClickedDistance, UGravityBikeSplineAttackShipOpenHatchTriggerComponent);
		}
	}
};
#endif