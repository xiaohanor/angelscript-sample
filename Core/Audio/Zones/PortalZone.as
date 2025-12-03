UCLASS(Meta = (NoSourceLin), HideCategories = "Collision Rendering Cooking Debug")
class APortalZone : AHazeAudioZone
{
	default SetTickGroup(ETickingGroup::TG_EndPhysics);
	default ZoneType = EHazeAudioZoneType::Portal;
	default BrushComponent.SetCollisionProfileName(n"AudioZone");
	default ZoneFadeTargetValue = 1.0;
	default FadeAxes = FVector(1.0, 1.0, 0.0);

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.SpriteName = "ZonePortal";
	default EditorIcon.RelativeScale3D = FVector(2);
#endif

	UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category="Audio")
	FVector ConnectionsExtents;

	TArray<float> ZoneShares;
	default ZoneShares.SetNum(2);

	private float ZoneAShare = 0.0;
	private float ZoneBShare = 0.0;

	private bool bHasInitializedFade = false;
	private float StartTime = 0;
	private const float MaxSpawnFadeInDuration = 0.5;

	UFUNCTION()
	void SetZoneRelevance(float NewRelevance)
	{
		Relevance = NewRelevance;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		AudioZone::OnBeginPlay(this);
		StartTime = Time::GetGameTimeSeconds() + MaxSpawnFadeInDuration;
	}

	void GetNearestPlane(const FVector& A, const FVector& B, const FVector& Extents, FVector& PlaneNormal, float& Sign, FVector& MaxDistanceOnAxis)
	{
		FVector Direction = A - B;
		Direction.Normalize();
		Direction.Z = 0;

		float DotForward = Direction.DotProduct(BrushComponent.ForwardVector);
		float DotUp = Direction.DotProduct(BrushComponent.UpVector);
		float DotRight = Direction.DotProduct(BrushComponent.RightVector);
		float MaxDot = Math::Max(Math::Abs(DotForward), Math::Max(Math::Abs(DotUp), Math::Abs(DotRight)));

		if (Math::Abs(DotForward) == MaxDot)
		{
			PlaneNormal = BrushComponent.ForwardVector; 
			MaxDistanceOnAxis = FVector::ForwardVector * Extents.X;
			Sign = Math::Sign(DotForward);
		}
		if (Math::Abs(DotUp) == MaxDot)
		{
			PlaneNormal = BrushComponent.UpVector; 
			MaxDistanceOnAxis = FVector::UpVector * Extents.Z;
			Sign = Math::Sign(DotUp);
		}
		if (Math::Abs(DotRight) == MaxDot)
		{
			PlaneNormal = BrushComponent.RightVector;
			MaxDistanceOnAxis = FVector::RightVector * Extents.Y;
			Sign = Math::Sign(DotRight);
		}

		// PlaneNormal *= Sign;
	}

	FVector CalculateLocalExtents()
	{
		FTransform NoRotationTransform = BrushComponent.WorldTransform;
		NoRotationTransform.SetRotation(FQuat::Identity);

		FVector BoxMax = -FVector::OneVector * MAX_flt;
		FVector BoxMin = FVector::OneVector * MAX_flt;
		
		auto AllPolys = GetPolys();
		for	(auto Poly: AllPolys)
		{
			for (const auto& Vertex : Poly.Vertices)
			{
				auto TransformedPosition = NoRotationTransform.TransformPosition(Vertex);
				BoxMin.X = Math::Min(BoxMin.X, TransformedPosition.X);
				BoxMin.Y = Math::Min(BoxMin.Y, TransformedPosition.Y);
				BoxMin.Z = Math::Min(BoxMin.Z, TransformedPosition.Z);

				BoxMax.X = Math::Max(BoxMax.X, TransformedPosition.X);
				BoxMax.Y = Math::Max(BoxMax.Y, TransformedPosition.Y);
				BoxMax.Z = Math::Max(BoxMax.Z, TransformedPosition.Z);
			}
		}

		return FBox(BoxMin, BoxMax).GetExtent();
	}

	private bool GetPositionOutsideOfZone(AHazeAudioZone Zone, const FVector& A, const FVector& B
		,  FVector& InsidePosition,  FVector& OutsidePosition, FVector& ClosestOutPosition)
	{
		if (Zone == nullptr)
			return false;

		bool bEdgeInside = Zone.BrushComponent.GetClosestPointOnCollision(A, ClosestOutPosition) == 0;

		if (!bEdgeInside)
		{
			OutsidePosition = A;
			InsidePosition = B;
			return true;
		}

		bEdgeInside = Zone.BrushComponent.GetClosestPointOnCollision(B, ClosestOutPosition) == 0;
		if (!bEdgeInside)
		{
			OutsidePosition = B;
			InsidePosition = A;
			return true;
		}

		return false;
	}

	bool CalculateBoundsForZones(
		FAmbientZonePortalConnections& ZoneConnection
		, AHazeAudioZone OtherZone
		, UHazeScriptComponentVisualizer Visualizer = nullptr)
	{
		// ZoneConnection.Reset();

		if (ZoneConnection.Zones.Num() == 0)
			return false;

		// Cut the portals extents in to two
		auto Extents = CalculateLocalExtents();
		auto BoundsOrigin = BrushComponent.BoundsOrigin;

		FVector DirectionalVector;
		FVector MaxDistanceOnAxis;
		float Sign = 1.0;
		float MaxDistance = 0.0;

		FVector OutPosition;
		// Inside or outside
		FVector EdgeInside;
		FVector EdgeOutside;
		
		// Reset
		Connections.SelectedZone = 0;

		for (auto Zone: Connections.Zones)
		{
			GetNearestPlane(
				BoundsOrigin, Zone.BrushComponent.BoundsOrigin, 
				Extents, DirectionalVector, Sign, MaxDistanceOnAxis);
			MaxDistance = MaxDistanceOnAxis.AbsMax;

			// Edge of the bounds
			FVector PortalEdge = BoundsOrigin + DirectionalVector * MaxDistance;
			FVector PortalsEdgeInsideZone = BoundsOrigin - DirectionalVector * MaxDistance;

			if (GetPositionOutsideOfZone(Zone, PortalEdge, PortalsEdgeInsideZone, EdgeInside, EdgeOutside, OutPosition))
			{
				break;
			}

			++Connections.SelectedZone;
		}

		// Now we can calculate based on at least one zone.
		MaxDistance = (EdgeInside - EdgeOutside).Size();
		DirectionalVector = (EdgeInside - EdgeOutside).GetSafeNormal();
	
		FVector FindClosestPointOnZone = Math::LinePlaneIntersection(
			// Point A, B
			EdgeInside, EdgeOutside,
			// Position and Normal
			OutPosition, (OutPosition - EdgeOutside).GetSafeNormal());

		// Get the Distance from the outer edge of the AmbientZone and end of the PortalZone
		// FVector FromEdgeToEdge = (EdgeInside - FindClosestPointOnZone);
		// float ExtentsDistance = FromEdgeToEdge.Size();

		// Sign the entrance direction, so we get the correct plane normal in runtime
		ZoneConnection.EntranceAxis = DirectionalVector;
		// auto ExtentToRemove = MaxDistanceOnAxis * (1 - (ExtentsDistance / MaxDistance));
		
		ZoneConnection.Extents = Extents;
		ZoneConnection.Origin = BoundsOrigin; //FindClosestPointOnZone - DirectionalVector * ExtentsDistance * 0.5; // - Direction * Distance * 0.5;
		ConnectionsExtents = Extents * 2;
		
		// ZoneConnection.MinScaleValue = 1 - (ExtentsDistance)/MaxDistance;
		ZoneConnection.EntranceOrigin = EdgeInside;

		FLinearColor ColorTest = FLinearColor::Green;
		{
			Visualizer.DrawArrow(EdgeInside, EdgeInside + (OutPosition - EdgeOutside).GetSafeNormal() * 100, ColorTest, 50, 5);
			Visualizer.DrawArrow(EdgeInside, FindClosestPointOnZone, ColorTest, 50, 5);
			Visualizer.DrawPoint(ZoneConnection.EntranceOrigin, ColorTest, 59);
			Visualizer.DrawWireBox(ZoneConnection.Origin, ZoneConnection.Extents, GetActorRotation().Quaternion(), ColorTest, Thickness = AudioZone::LineThickness);
		}

		return true;
	}

	void CalculateBounds(UHazeScriptComponentVisualizer Visualizer = nullptr)
	{
		CalculateBoundsForZones(Connections, nullptr, Visualizer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!bHasInitializedFade)
		{
			if (StartTime > Time::GetGameTimeSeconds())
			{
				// We use the ZoneRTPC as a scale value
				MoveZoneRtpcToTarget(ZoneFadeTargetValue, DeltaSeconds);
			}
			else
			{
				ZoneRTPCValue = ZoneFadeTargetValue;
				bHasInitializedFade = true;
			}
		}
		else
			ZoneRTPCValue = ZoneFadeTargetValue;

		if (!bShouldTick && ZoneRTPCValue == ZoneFadeTargetValue)
		{
			SetZoneTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnZoneTickEnabled(bool bTickEnabled)
	{
		if (bTickEnabled)
			ZoneFadeTargetValue = 1.0;
	}
}
