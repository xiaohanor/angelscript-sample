class USkylineGeckoDraggedBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	USkylineGeckoSettings Settings;

	USkylineGeckoComponent GeckoComp;
	UGravityWhipResponseComponent WhipResponse;
	UGravityWhippableComponent WhippableComp;
	UBasicAIHealthComponent HealthComp;

	FHazeNavmeshPoly CurNavPoly;
	AHazePlayerCharacter Whipper;

	float MaxDistance;
	FHazeAcceleratedVector Velocity;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USkylineGeckoSettings::GetSettings(Owner);
		GeckoComp = USkylineGeckoComponent::GetOrCreate(Owner);
		WhippableComp = UGravityWhippableComponent::GetOrCreate(Owner);
		WhipResponse = UGravityWhipResponseComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);

		// If we have this behaviour, we should always be whippable
		GeckoComp.ApplyWhipGrab(true, EGravityWhipGrabMode::Drag, this);

		WhipResponse.OnGrabbed.AddUFunction(this, n"OnGrabbed");
		WhipResponse.OnReleased.AddUFunction(this, n"OnReleased");
		WhipResponse.OnThrown.AddUFunction(this, n"OnThrown");
	}

	UFUNCTION()
	private void OnGrabbed(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, TArray<UGravityWhipTargetComponent> OtherComponents)
	{
		WhippableComp.bGrabbed = true;
	}

	UFUNCTION()
	private void OnThrown(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FHitResult HitResult, FVector Impulse)
	{
		OnReleased(UserComponent, TargetComponent, Impulse);
	}

	UFUNCTION()
	private void OnReleased(UGravityWhipUserComponent UserComponent, UGravityWhipTargetComponent TargetComponent, FVector Impulse)
	{
		if (!IsActive())
			return;
		WhippableComp.bGrabbed = false;
		Owner.AddMovementImpulse(Impulse * 0.5);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;	
		if (!WhippableComp.bGrabbed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if (!WhippableComp.bGrabbed)
 			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();

		Whipper = Game::Zoe;
		CurNavPoly = Navigation::FindNearestPoly(Owner.ActorLocation, 400.0);

		MaxDistance = Math::Min(Settings.WhipDraggedMaxRange, Owner.ActorLocation.Distance(Whipper.ActorLocation) + 200.0);
		Velocity.SnapTo(FVector::ZeroVector);

		AnimComp.RequestFeature(FeatureTagGecko::Taunts, EBasicBehaviourPriority::Medium, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Whipper.ClearPointOfInterestByInstigator(this);
		WhippableComp.bGrabbed = false;
		HealthComp.SetStunned();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;

		// TODO: Handle being dragged along climb splines
		if (!CurNavPoly.IsValid() || !OwnLoc.IsWithinDist2D(CurNavPoly.GetClosestPointOnPoly(OwnLoc), 1.0))
			CurNavPoly = Navigation::FindNearestPoly(OwnLoc, 40.0);

		FVector DragDest = UpdateDragDestinationOnNavMesh(DeltaTime);
		if (DragDest.IsWithinDist(OwnLoc, 40.0))
		{
			Velocity.AccelerateTo(FVector::ZeroVector, 0.5, DeltaTime);
		}
		else
		{
			FVector DestDir = (DragDest - OwnLoc).GetSafeNormal2D();
			Velocity.AccelerateTo(DestDir * 4000.0, 0.5, DeltaTime);
			DestinationComp.MoveTowardsIgnorePathfinding(DragDest, Velocity.Value.DotProduct(DestDir));
		}

		DestinationComp.RotateTowards(Whipper);

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			CurNavPoly.DrawDebugNavmeshPoly(FLinearColor::Yellow);
			Debug::DrawDebugLine(DragDest, DragDest + FVector(0,0,100), FLinearColor::Yellow);
		}
#endif		
	}	

	FVector UpdateDragDestinationOnNavMesh(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		if (!CurNavPoly.IsValid())
			return OwnLoc; // Don't move where there is no navmesh 

		float MinDist = 1.0;
		float WantedDistance = Math::Clamp(Whipper.ActorLocation.Distance(OwnLoc), Settings.WhipDraggedMinRange, MaxDistance); 
		FVector DragDest = (Whipper.ActorLocation + Whipper.ViewRotation.ForwardVector.GetSafeNormal2D() * WantedDistance);
		DragDest.Z = CurNavPoly.Center.Z; 	

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugLine(DragDest, DragDest + FVector(0,0,200));
			Debug::DrawDebugLine(DragDest, OwnLoc);
		}
#endif

		FVector PolyLoc = CurNavPoly.GetClosestPointOnPoly(DragDest);
		if (PolyLoc.IsWithinDist2D(DragDest, MinDist + 1.0))
			return PolyLoc; // Drag destination is within current poly

		// Check if we can be dragged towards a neighbour
		FVector Intersection;
		TArray<FHazeNavmeshEdge> Edges;
		CurNavPoly.GetEdges(Edges);
		for (FHazeNavmeshEdge Edge : Edges)
		{
			if (Math::SegmentIntersection2D(OwnLoc, DragDest, Edge.Left, Edge.Right, Intersection))
				return DragDest;
		}

		// No suitable neighbour, get dragged to edge of poly
		TArray<FVector> Verts;
		if (!ensure(CurNavPoly.GetVertices(Verts) > 2))
			return OwnLoc;
		FVector PrevVert = Verts.Last();
		for (FVector Vert : Verts)
		{
			if (Math::SegmentIntersection2D(OwnLoc, DragDest, PrevVert, Vert, Intersection) && 
				!Intersection.IsWithinDist2D(OwnLoc, MinDist + 0.1))
			{
				// Found the edge of poly furthest away in the wanted direction, pull there
				if (OwnLoc.IsWithinDist2D(Intersection, 100.0))
					return OwnLoc + (Intersection - OwnLoc).GetSafeNormal2D() * 100.0; 
				return Intersection;
			}
			PrevVert = Vert;
		}

		// We're already at the edge of poly, try to slide along it to get around obstructions
		PrevVert = Verts.Last();
		FVector NearEdgeStart;
		FVector NearEdgeEnd;
		float NearEdgeDistSqr = BIG_NUMBER;
		for (FVector Vert : Verts)
		{
			FVector EdgeLoc = Math::ProjectPositionOnInfiniteLine(PrevVert, Vert - PrevVert, OwnLoc);
			float EdgeDistSqr = OwnLoc.DistSquared(EdgeLoc);
			if (EdgeDistSqr < NearEdgeDistSqr)
			{
				NearEdgeStart = PrevVert;
				NearEdgeEnd = Vert;
				NearEdgeDistSqr = EdgeDistSqr;
			}
			PrevVert = Vert;
		}
		if (NearEdgeDistSqr < BIG_NUMBER)
		{
			// Drag past edge end nearest destination
			FVector EdgeDest = (NearEdgeStart.DistSquared2D(DragDest) < NearEdgeEnd.DistSquared2D(DragDest)) ? NearEdgeStart : NearEdgeEnd;
			FVector DragDir = (EdgeDest - OwnLoc).GetSafeNormal2D();
			FVector DragLoc = OwnLoc + DragDir * 100.0;
			if (Whipper.ActorLocation.IsWithinDist2D(DragLoc, Settings.WhipDraggedMaxRange))
				return DragLoc;

			// Drag no further than the limits of allowed range	
			FLineSphereIntersection SphereIntersect =  Math::GetInfiniteLineSphereIntersectionPoints(OwnLoc, DragDir, Whipper.ActorLocation, Settings.WhipDraggedMaxRange);
			if (SphereIntersect.bHasIntersection)
				return SphereIntersect.MaxIntersection;
		}

		// Could not find edge
//		check(false);
		return OwnLoc;
	}
}