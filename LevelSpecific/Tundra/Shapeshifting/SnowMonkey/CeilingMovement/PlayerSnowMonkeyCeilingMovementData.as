class UTundraPlayerSnowMonkeyCeilingMovementData : USteppingMovementData
{
	access Protected = protected, UTundraPlayerSnowMonkeyCeilingMovementResolver (inherited);

	default DefaultResolverType = UTundraPlayerSnowMonkeyCeilingMovementResolver;

	access:Protected
	FTundraPlayerSnowMonkeyCeilingData CurrentCeiling;

	access:Protected
	TArray<FTundraPlayerSnowMonkeyCeilingData> AdjacentCeilings;
	
	access:Protected
	float CeilingEdgeSlideMinSpeed;

	access:Protected
	float CeilingMaxSpeed;

	access:Protected
	FVector MovementInput;

	// Temporal log stuff
	access:Protected
	const FString CategoryAdjacentCeilingOverlaps = "18#Adjacent Ceiling Overlaps";
	// End temporal log stuff

	access:Protected
	bool PrepareMove(const UHazeMovementComponent MovementComponent, FVector CustomWorldUp = FVector::ZeroVector) override
	{
		if(!Super::PrepareMove(MovementComponent, CustomWorldUp))
			return false;
		
		auto ClimbComp = UTundraPlayerSnowMonkeyComponent::Get(MovementComponent.Owner).CurrentCeilingComponent;
		devCheck(ClimbComp != nullptr, "Current ceiling component property in snow monkey component was null when tried to prepare move");

		CurrentCeiling = ClimbComp.GetCeilingData();
		auto MonkeySettings = UTundraPlayerSnowMonkeySettings::GetSettings(MovementComponent.HazeOwner);
		CeilingEdgeSlideMinSpeed = MonkeySettings.CeilingEdgeSlideMinSpeed;
		CeilingMaxSpeed = MonkeySettings.CeilingMovementSpeed;
		MovementInput = MovementComponent.MovementInput;

		TArray<FOverlapResult> OverlapArray;
		TArray<FOverlapResultArray> OverlapResultArrays;
		FHazeTraceSettings OverlapSettings = Trace::InitProfile(n"BlockAllDynamic");
		OverlapSettings.IgnoreActor(ClimbComp.Owner);
		OverlapSettings.IgnorePlayers();

		if(CurrentCeiling.Spline != nullptr) // Overlap check when we are on a spline
		{
			FTransform StartTransform = CurrentCeiling.Spline.GetWorldTransformAtSplineDistance(0.0);
			float SplineStartWidth = CurrentCeiling.SplineMeshWidth * StartTransform.Scale3D.Y - CurrentCeiling.Pushback;

			FVector BoxExtents = FVector(50.0, SplineStartWidth, 50.0);
			OverlapSettings.UseBoxShape(BoxExtents, StartTransform.Rotation);

			FOverlapResultArray ResultArray = OverlapSettings.QueryOverlaps(StartTransform.Location);
			OverlapArray.Append(ResultArray.GetBlockHits());
			OverlapResultArrays.Add(ResultArray);

			FTransform EndTransform = CurrentCeiling.Spline.GetWorldTransformAtSplineDistance(CurrentCeiling.Spline.SplineLength);
			float SplineEndWidth = CurrentCeiling.SplineMeshWidth * EndTransform.Scale3D.Y - CurrentCeiling.Pushback;

			BoxExtents = FVector(50.0, SplineEndWidth, 50.0);
			OverlapSettings.UseBoxShape(BoxExtents, EndTransform.Rotation);

			ResultArray = OverlapSettings.QueryOverlaps(EndTransform.Location);
			OverlapArray.Append(ResultArray.GetBlockHits());
			OverlapResultArrays.Add(ResultArray);
		}
		else // Overlap check when we are on a normal mesh
		{
			OverlapSettings.UseBoxShape(CurrentCeiling.CeilingLocalBounds.Extent * CurrentCeiling.CeilingTransform.Scale3D + FVector(20.0), CurrentCeiling.CeilingTransform.Rotation);
			FOverlapResultArray OverlapResults = OverlapSettings.QueryOverlaps(CurrentCeiling.CeilingTransform.TransformPosition(CurrentCeiling.CeilingLocalBounds.Center));

			OverlapResultArrays.Add(OverlapResults);
			OverlapArray = OverlapResults.GetBlockHits();
		}

		AdjacentCeilings.Empty();
		TArray<AActor> AlreadyAddedActors;
		for(auto Overlap : OverlapArray)
		{
			auto Current = UTundraPlayerSnowMonkeyCeilingClimbComponent::Get(Overlap.Actor);
			if(Current == nullptr)
				continue;

			if(Current.IsDisabled())
				continue;

			if(!Current.ComponentIsClimbable(Overlap.Component))
				continue;

			if(AlreadyAddedActors.Contains(Overlap.Actor))
				continue;

			AlreadyAddedActors.Add(Overlap.Actor);
			AdjacentCeilings.Add(Current.GetCeilingData());
		}

		#if !RELEASE
		for(int i = 0; i < OverlapResultArrays.Num(); i++)
		{
			FString Label = f"{i + 1}";
			if(CurrentCeiling.Spline != nullptr)
			{
				if(i == 0)
					Label = "Spline Start";
				else if(i == 1)
					Label = "Spline End";
			}
			else if(i == 0)
				Label = "Cube Overlap";

			FTemporalLog Movement = TEMPORAL_LOG(MovementComponent.GetOwner(), "Movement");
			FTemporalLog Traces = Movement.Page("Traces");
			Traces.OverlapResults(f"{CategoryAdjacentCeilingOverlaps};{Label}", OverlapResultArrays[i]);
			for(int j = 0; j < AdjacentCeilings.Num(); j++)
			{
				Traces.Value(f"Adjacent Ceiling[{j}]", AdjacentCeilings[j].ClimbComp.Owner.ActorNameOrLabel);
			}
		}
		#endif

		return true;
	}

#if EDITOR
	access:Protected
	void CopyFrom(const UBaseMovementData OtherBase) override
	{
		Super::CopyFrom(OtherBase);
		
		auto Other = Cast<UTundraPlayerSnowMonkeyCeilingMovementData>(OtherBase);
		CurrentCeiling = Other.CurrentCeiling;
		AdjacentCeilings = Other.AdjacentCeilings;
		CeilingEdgeSlideMinSpeed = Other.CeilingEdgeSlideMinSpeed;
		CeilingMaxSpeed = Other.CeilingMaxSpeed;
		MovementInput = Other.MovementInput;
	}
#endif
}