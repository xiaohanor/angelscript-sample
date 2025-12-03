class USanctuaryWeeperViewComponent : UActorComponent
{
	AHazeActor HazeOwner;
	USanctuaryWeeperSettings WeeperSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		WeeperSettings = USanctuaryWeeperSettings::GetSettings(HazeOwner);
	}

	bool ShouldFreeze()
	{
		AHazePlayerCharacter Onlooker;
		return HasOnlooker(WeeperSettings.FreezeRadius, Onlooker);
	}

	bool ShouldDodge(FVector& Direction)
	{
		AHazePlayerCharacter Onlooker;
		bool ShouldDodge = HasOnlooker(WeeperSettings.DodgeRadius, Onlooker);
		
		if(ShouldDodge)
		{
			FVector ProjectedLoc = Math::ClosestPointOnInfiniteLine(Onlooker.ViewLocation, Onlooker.ViewLocation + Onlooker.ViewRotation.Vector(), HazeOwner.ActorCenterLocation);
			FVector LeftVector = HazeOwner.ActorRightVector * -1;
			bool DodgeRight = (HazeOwner.ActorLocation + HazeOwner.ActorRightVector).Distance(ProjectedLoc) > (HazeOwner.ActorLocation + LeftVector).Distance(ProjectedLoc);
			if(DodgeRight)
				Direction = HazeOwner.ActorRightVector;
			else
				Direction = LeftVector;
		}
		
		return ShouldDodge;
	}

	bool HasOnlooker(float Radius, AHazePlayerCharacter& Onlooker)
	{
		for(AHazePlayerCharacter Player: Game::Players)
		{
			if(WeeperSettings.FreezeIgnoreMioView && Player == Game::Mio)
				continue;
			if(WeeperSettings.FreezeIgnoreZoeView && Player == Game::Zoe)
				continue;

			if(!IsNearView(HazeOwner.ActorCenterLocation, Radius, Player))
				continue;
			
			Onlooker = Player;
			return true;
		}
		return false;
	}

	private bool IsNearView(FVector Location, float Radius, AHazePlayerCharacter ViewPlayer)
	{
	    float VerticalFOV = 70.0;
        float HorizontalFOV = 70.0;
		if (!GetFOVs(ViewPlayer, VerticalFOV, HorizontalFOV))
			return false;

		FVector ViewLoc = ViewPlayer.ViewLocation;
		FVector ViewRight = ViewPlayer.ViewRotation.RightVector;
		FVector ViewUp = ViewPlayer.ViewRotation.UpVector;

		FVector TopNormal = ViewUp.RotateAngleAxis(-VerticalFOV * 0.5, ViewRight);
		FVector BottomNormal = -ViewUp.RotateAngleAxis(VerticalFOV * 0.5, ViewRight);
		FVector RightNormal = ViewRight.RotateAngleAxis(HorizontalFOV * 0.5, ViewUp);
		FVector LeftNormal = -ViewRight.RotateAngleAxis(-HorizontalFOV * 0.5, ViewUp);

		return (IsNearPlaneWedge(Location, Radius, ViewLoc, RightNormal, LeftNormal) && 
				IsNearPlaneWedge(Location, Radius, ViewLoc, TopNormal, BottomNormal));
	}

	private bool IsNearPlaneWedge(FVector Location, float Radius, FVector WedgeIntersection, FVector WedgeTopNormal, FVector WedgeBottomNormal)
	{
		// Check if center is within radius from the wedge starting where the planes intersect and stretching in the wedge direction. 
		if (Location.IsWithinDist(WedgeIntersection, Radius))
			return true;

		FVector TopProjection = Location.PointPlaneProject(WedgeIntersection, WedgeTopNormal);
		if (!TopProjection.IsWithinDist(Location, Radius) && (WedgeTopNormal.DotProduct(Location - TopProjection) > 0.0))
			return false; // Outside top plane

		FVector BottomProjection = Location.PointPlaneProject(WedgeIntersection, WedgeBottomNormal);
		if (!BottomProjection.IsWithinDist(Location, Radius) && WedgeBottomNormal.DotProduct(Location - BottomProjection) > 0.0)
			return false; // Outside bottom plane

		// Within wedge (though not near wedge surfaces)
		return true;
	}

	private bool GetFOVs(AHazePlayerCharacter Player, float& VerticalFOV, float& HorizontalFOV)
	{
		float AspectRatio = GetViewAspectRatio(Player);
		if (Math::IsNaN(AspectRatio))
			return false;

		// Assuming we use vertical FOV:
		float FOV = Player.ViewFOV;
        VerticalFOV = Math::Clamp(FOV, 5.0, 89.0);
        HorizontalFOV = Math::Clamp(Math::RadiansToDegrees(2 * Math::Atan(Math::Tan(Math::DegreesToRadians(FOV * 0.5)) * AspectRatio)), 5.0, 179.0);
		return true;
	}

	private float GetViewAspectRatio(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return (8.0 / 9.0);

        FVector2D Resolution = SceneView::GetPlayerViewResolution(Player);
		if(SceneView::GetFullScreenPlayer() == Player.OtherPlayer)
        	Resolution = SceneView::GetPlayerViewResolution(Player.OtherPlayer);

		if (Resolution.ContainsNaN())
			return NAN_flt;

		return Resolution.X / Math::Max(1.0, Resolution.Y);
	}
}