
class USkylineGeckoStalkBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UBasicAIRuntimeSplineComponent SplineComp;
	USkylineGeckoComponent GeckoComp;
	UWallclimbingComponent WallclimbingComp;
	USkylineGeckoSettings Settings;
	AHazePlayerCharacter PlayerTarget;
	FVector Destination;
	FWallclimbingNavigationFace DestinationPoly;

	FHazeAcceleratedFloat AccMoveSpeed;
	float TargetSpeed;
	float SpeedChangeTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		SplineComp = UBasicAIRuntimeSplineComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		WallclimbingComp = UWallclimbingComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (WallclimbingComp.Navigation == nullptr)
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if(!Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.StalkMaxRange))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		PlayerTarget = Cast<AHazePlayerCharacter>(TargetComp.Target);

		FWallclimbingNavigationFace CurPoly; 
		if (!WallclimbingComp.Navigation.FindClosestNavmeshPoly(Owner.ActorLocation, CurPoly, 0.0, 200.0, 100.0, Owner.ActorUpVector) ||
		 	!GetDestination(CurPoly, Destination, DestinationPoly))
		{
			// Failed to find a destination, try for a new one in a while
			Cooldown.Set(Math::RandRange(0.3, 0.7)); 
		}

		SpeedChangeTime = -1.0;
		AccMoveSpeed.SnapTo(Math::Clamp(Owner.ActorVelocity.Size(), GetTargetSpeed(), Settings.StalkMoveSpeedHigh));
		TargetSpeed = AccMoveSpeed.Value;


		GeckoComp.bAllowBladeHits.Apply(false, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GeckoComp.bAllowBladeHits.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(TargetComp.Target == nullptr)
			return;
		if (Cooldown.IsSet())
			return; // Failed to find a destination

		if (ActiveDuration > Settings.StalkMaxDuration)
			PauseStalking();

		FVector OwnLoc = Owner.ActorLocation;
		if (OwnLoc.IsWithinDist(Destination, Settings.StalkAtDestinationRange))
		{
			// Find a new destination
			if (!GetDestination(DestinationPoly, Destination, DestinationPoly))
			{
				Cooldown.Set(Settings.StalkPause * Math::RandRange(0.5, 1.5));
				return;
			}
		}
		
		// Sneak along
		float MoveSpeed = UpdateMoveSpeed(DeltaTime);
		DestinationComp.MoveTowards(Destination, MoveSpeed);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(Owner.FocusLocation, Destination, FLinearColor::LucBlue, 1.0);
			Debug::DrawDebugSphere(Destination, 20.0, 4, FLinearColor::LucBlue, 5.0);
		}
#endif
	}

	void PauseStalking()
	{
		// Take a break for a while
		Cooldown.Set(Settings.StalkPause * Math::RandRange(0.5, 1.5));
		return;
	}

	bool GetDestination(FWallclimbingNavigationFace StartingPoly, FVector& Dest, FWallclimbingNavigationFace& NextPoly)
	{
		// Keep going to next neighbour in the wanted direction until we:
		// - Reach an acceptable range
		// - Have passed enough neighbours
		// - Find a neighbour which we need to switch gravity to reach
		// - Fail to find a neighbour in wanted direction
		FWallclimbingNavigationFace CurPoly = StartingPoly;
		FVector OwnLoc = Owner.ActorLocation;
		FVector Direction = GetIdealStalkDirection();
		FVector StartCenter = CurPoly.Center;
		FVector CurStart = StartCenter; // We use poly center instead of own location since we might start outside of poly
		FVector StartNormal = CurPoly.Normal;
		float MaxDist = Settings.StalkMoveSpeedLow * Settings.StalkMaxDuration;
		for (int i = 0; (i < 20) && CurStart.IsWithinDist(OwnLoc, MaxDist) && (CurPoly.Normal.DotProduct(StartNormal) > 0.866); i++)
		{
#if EDITOR
			if (Owner.bHazeEditorOnlyDebugBool)
				CurPoly.DebugDraw(FLinearColor::DPink * 0.2, 2.0);
#endif			
			FWallclimbingNavigationFace NextNeighbour;
			if (FindNeighbourInDirection(CurPoly, Direction, StartCenter, CurStart, NextNeighbour))
				CurPoly = NextNeighbour;
			else
				break;
		}	

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			CurPoly.DebugDraw(FLinearColor::Green * 0.2, 2.0);
			Debug::DrawDebugArrow(Owner.ActorLocation + Owner.ActorUpVector * 100.0, Owner.ActorLocation + Owner.ActorUpVector * 100.0 + Direction * 200.0, 10.0, FLinearColor::Yellow, 5, 2.0);
		}
#endif	

		if (CurStart.IsWithinDist(CurPoly.Center, 1.0))
			return false;

		// We want to move normally to last edge _before_ the next poly so 
		// we then can gravity switch onto next poly if appropriate
		Dest = CurStart; 
		NextPoly = CurPoly;	
		return true;
	}

	bool FindNeighbourInDirection(FWallclimbingNavigationFace CurPoly, FVector Direction, FVector StartCenter, FVector& CurStart, FWallclimbingNavigationFace& WantedNeighbour)
	{
		// Tweak direction if it's parallell to poly normal
		FVector Dir = Direction;
		if (Math::Abs(Dir.DotProduct(CurPoly.Normal)) > 0.999) 
			Dir = Dir * 0.9 + Math::GetRandomPointOnSphere().ConstrainToPlane(CurPoly.Normal).GetSafeNormal() * 0.1;
		
		// Continue onwards through the edge leaving poly which the plane our direction and the poly normal spans
		FVector DirectionalPlaneNormal = Dir.CrossProduct(CurPoly.Normal);
		for (FWallclimbingNavigationNeighbour Neighbour : CurPoly.Neighbours)
		{
			if (Neighbour.Center.IsWithinDist(StartCenter, 1.0))
				continue; // We're back where we started	
			FVector Intersection;
			if (!Math::IsLineSegmentIntersectingPlane(Neighbour.EdgeLeft, Neighbour.EdgeRight, DirectionalPlaneNormal, CurStart, Intersection))
				continue;
			if (Dir.DotProduct(Intersection - CurStart) < SMALL_NUMBER)
				continue; // This edge is backwards (probably the edge we entered through)	
			// Found neighbour to pass on to
			CurStart = Intersection;
			WantedNeighbour = WallclimbingComp.Navigation.NavMesh[Neighbour.iToPoly];
			return true;		
		}
		return false;
	}

	FVector GetIdealStalkDirection()
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Dir = Owner.ActorForwardVector;
		if (SceneView::IsInView(PlayerTarget, OwnLoc, FVector2D(0.2, 0.8), FVector2D(0.2, 0.8)))
		{
			// Move somewhat forward
			Dir = Owner.ActorForwardVector.RotateAngleAxis(Math::RandRange(-1.0, 1.0) * Settings.StalkInViewMaxDirectionChange, Owner.ActorUpVector);
			FVector AheadLoc = OwnLoc + Dir * 200.0;
			if (AheadLoc.Z < Game::Zoe.ActorLocation.Z + Settings.StalkAboveZoeHeight)
			{
				// Zoe is at or near floor, we prefer walls/ceiling
				AheadLoc.Z = Game::Zoe.ActorLocation.Z + Settings.StalkAboveZoeHeight;
				Dir = (AheadLoc - OwnLoc).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
			}
		}
		else
		{
			// Move in front of player
			FVector InFrontLoc = (PlayerTarget.FocusLocation + PlayerTarget.ViewRotation.ForwardVector * Settings.StalkMaxRange);
			InFrontLoc.Z = Math::Max(InFrontLoc.Z, Game::Zoe.ActorLocation.Z + Settings.StalkAboveZoeHeight); // Zoe is at or near floor, we prefer walls/ceiling
			Dir = (InFrontLoc - OwnLoc).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();	
		} 

		// Stay away from players
		FVector Avoid = FVector::ZeroVector;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector NearPassLoc; float Dummy;
			Math::ProjectPositionOnLineSegment(OwnLoc, OwnLoc + Dir * Settings.StalkAvoidPlayerRange, Player.ActorLocation, NearPassLoc, Dummy);
			if (!NearPassLoc.IsWithinDist(Player.ActorLocation, Settings.StalkAvoidPlayerRange * 2.0))
				continue;
			float AvoidStrength = Math::GetMappedRangeValueClamped(FVector2D(1.0, 2.0) * Settings.StalkAvoidPlayerRange, FVector2D(1.2, 0.0), (NearPassLoc - Player.ActorLocation).Size());
			FVector AvoidDir = (NearPassLoc - Player.ActorLocation).ConstrainToPlane(Owner.ActorUpVector);
			if (AvoidDir.IsNearlyZero(1.0))
				AvoidDir = (OwnLoc - Player.ActorLocation).ConstrainToPlane(Owner.ActorUpVector);
			Avoid += AvoidDir * AvoidStrength;		
		}
		if (!Avoid.IsZero())
			Dir = (Dir + Avoid).GetSafeNormal();

		return Dir;
	}

	float UpdateMoveSpeed(float DeltaTime)
	{
		float NewSpeed = GetTargetSpeed();
		if (Math::IsNearlyEqual(NewSpeed, TargetSpeed, 50.0))
		{
			TargetSpeed = NewSpeed;
			SpeedChangeTime = ActiveDuration + Math::RandRange(0.5, 1.5) * Settings.StalkSpeedChangeInterval;
		}		 
		AccMoveSpeed.AccelerateTo(TargetSpeed, Settings.StalkSpeedChangeDuration, DeltaTime);
		return AccMoveSpeed.Value;
	}

	float GetTargetSpeed()
	{
		if (ActiveDuration < SpeedChangeTime)
			return TargetSpeed;

		FVector OwnLoc = Owner.ActorCenterLocation;
		if (!SceneView::IsInView(Game::Mio, OwnLoc) && !SceneView::IsInView(Game::Zoe, OwnLoc))	
			return Settings.StalkMoveSpeedHigh;

		bool bOnFloor = (Owner.ActorUpVector.DotProduct(FVector::UpVector) > 0.866);	
		float Rnd = Math::RandRange(0.0, 1.0);
		if ((Rnd < 0.1) && !bOnFloor)
			return Settings.StalkMoveSpeedMin;	
		else if ((Rnd < 0.5) && !bOnFloor)
			return Settings.StalkMoveSpeedLow;	
		else if (Rnd < 0.9)
			return Settings.StalkMoveSpeedMedium;	
		else
			return Settings.StalkMoveSpeedHigh;
	}
}