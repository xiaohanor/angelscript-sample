// Only for EditorRendering.
class UIslandJetpackShieldotronTacticalWaypointComponent : UHazeEditorRenderedComponent
{
	UPROPERTY(EditAnywhere)
	bool bAlwaysShowInEditor = true;

	default SetHiddenInGame(true);

	AIslandJetpackShieldotronTacticalWaypoint Waypoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Waypoint = Cast<AIslandJetpackShieldotronTacticalWaypoint>(Owner);
	}
	
	UFUNCTION(BlueprintOverride)
	private void OnActorOwnerModifiedInEditor()
	{
		MarkAllDirty();
		bRenderWhileNotSelected = bAlwaysShowInEditor;
	}

	UFUNCTION(BlueprintOverride)
	void OnComponentModifiedInEditor()
	{
		MarkAllDirty();
		bRenderWhileNotSelected = bAlwaysShowInEditor;
	}

	private void MarkAllDirty()
	{
#if EDITOR
		TListedActors<AIslandJetpackShieldotronTacticalWaypoint> Waypoints;
		for (AIslandJetpackShieldotronTacticalWaypoint WP : Waypoints)
			WP.WaypointComp.MarkRenderStateDirty();
#endif
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
#if EDITOR
		Waypoint = Cast<AIslandJetpackShieldotronTacticalWaypoint>(Owner);

		SetActorHitProxy();
		DrawWireSphere(WorldLocation, Waypoint.Radius , FLinearColor::Green, 5);
		ClearHitProxy();
		TListedActors<AIslandJetpackShieldotronTacticalWaypoint> Waypoints;
		for (int i = 0; i < Waypoints.Num(); i++)
		{
			if (Waypoints[i] == Waypoint)
				continue;

			if (Waypoint.ActorLocation.Distance(Waypoints[i].ActorLocation) <= Waypoint.Radius + Waypoints[i].Radius) // Temp
				DrawLine(Waypoint.ActorLocation, Waypoints[i].ActorLocation, Thickness = 2);
				//DrawArrow(Waypoint.ActorLocation, Waypoints[i].ActorLocation, ArrowSize=20, Thickness = 2);
		}
#endif
	}
	
};