class UCameraFrustumBoundaryResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);
	
	UBaseMovementResolver Resolver;
	FCameraFrustumBoundarySettings Settings;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UCameraFrustumBoundaryResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		Settings = Other.Settings;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);
		
		Resolver = Cast<UBaseMovementResolver>(InResolver);

		auto Comp = UCameraFrustumBoundaryComponent::Get(Resolver.Owner);
		if (Comp != nullptr)
			Settings = Comp.Settings.Get();
	}

	bool OnPrepareNextIteration(bool bFirstIteration) override
	{
		FVector CurrentLocation = Resolver.IterationState.CurrentLocation;
		FVector WorldUp = Resolver.IterationState.WorldUp;

		FMovementDelta TotalDelta; 
		for (auto It : Resolver.IterationState.DeltaStates)
			TotalDelta += It.Value.ConvertToDelta();

		FMovementDelta NewDelta;
		if (CalculateWantedDelta(CurrentLocation, WorldUp, TotalDelta, NewDelta))
		{
			for (auto It : Resolver.IterationState.DeltaStates)
			{
				FMovementDelta DeltaPart = It.Value.ConvertToDelta();
				float PartOfTotal = DeltaPart.Delta.Size() / TotalDelta.Delta.Size();

				DeltaPart.Delta = NewDelta.Delta * PartOfTotal;
				Resolver.IterationState.OverrideDelta(It.Key, DeltaPart);
			}
		}

		return true;
	}

	bool CalculateWantedDelta(FVector CurrentLocation, FVector WorldUp, FMovementDelta OriginalDelta, FMovementDelta&out NewDelta)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Resolver.Owner);

		FMovementDelta CurrentDelta = OriginalDelta;
		bool bDeltaModified = false;

		TArray<FPlane> Planes;
		SceneView::GetViewFrustumPlanes(Player, Planes);
		// Planes.Add(FPlane(Player.ActorLocation, FVector::ForwardVector));

		for (FPlane Plane : Planes)
		{
			FVector TargetLocation = CurrentLocation + CurrentDelta.Delta;

			FVector PlaneNormal = Plane.Normal;
			FVector OriginWithOffset = Plane.Origin + Settings.ViewWorldSpaceOffset;

			FVector TargetDifference = TargetLocation - OriginWithOffset;
			float TargetDot = PlaneNormal.DotProduct(TargetDifference);

			if (TargetDot > -Settings.MinimumDistanceFromFrustum)
			{
				FVector CurrentDifference = CurrentLocation - OriginWithOffset;
				float CurrentDot = PlaneNormal.DotProduct(CurrentDifference);
				if (TargetDot > CurrentDot)
				{
					float ClampedDot = Math::Min(TargetDot, Math::Max(-Settings.MinimumDistanceFromFrustum, CurrentDot));
					if (ClampedDot != TargetDot)
					{
						float Pushback = TargetDot - ClampedDot;
						float DeltaInDirection = CurrentDelta.Delta.DotProduct(PlaneNormal);
						if (DeltaInDirection > 0)
						{
							float Multiplier = 1.0 - (Pushback / DeltaInDirection);
							FVector IrrelevantDelta = CurrentDelta.Delta.VectorPlaneProject(PlaneNormal.VectorPlaneProject(WorldUp).GetSafeNormal());
							FVector RelevantDelta = CurrentDelta.Delta - IrrelevantDelta;

							CurrentDelta.Delta = RelevantDelta * Multiplier + IrrelevantDelta;
							bDeltaModified = true;
						}
					}
				}
			}

			// FVector Intersect = Plane.RayPlaneIntersection(Player.ActorLocation, Plane.Normal);
			// Debug::DrawDebugPlane(Intersect, Plane.Normal, 4000, 4000);
			// Debug::DrawDebugLine(Intersect, Intersect + Plane.Normal * 200, FLinearColor::Red);
		}

		if (bDeltaModified)
		{
			NewDelta = CurrentDelta;
			return true;
		}

		return false;
	}
}

class UCameraFrustumBoundaryComponent : UActorComponent
{
	TInstigated<FCameraFrustumBoundarySettings> Settings;
}

struct FCameraFrustumBoundarySettings
{
	// Stop the player this many units before hitting the frustum boundary
	UPROPERTY()
	float MinimumDistanceFromFrustum = 50.0;

	// Additional offset to be applied to the view origin in world space
	UPROPERTY(AdvancedDisplay)
	FVector ViewWorldSpaceOffset;
}

namespace Boundary
{

UFUNCTION(Category = "Player|Movement")
void ApplyMovementConstrainToCameraFrustum(AHazePlayerCharacter Player, FCameraFrustumBoundarySettings Settings, FInstigator Instigator)
{
	auto Comp = UCameraFrustumBoundaryComponent::GetOrCreate(Player);
	Comp.Settings.Apply(Settings, Instigator);

	auto MoveComp = UHazeMovementComponent::Get(Player);
	MoveComp.ApplyResolverExtension(UCameraFrustumBoundaryResolverExtension, Instigator);
}

UFUNCTION(Category = "Player|Movement")
void ClearMovementConstrainToCameraFrustum(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto Comp = UCameraFrustumBoundaryComponent::GetOrCreate(Player);
	Comp.Settings.Clear(Instigator);

	auto MoveComp = UHazeMovementComponent::Get(Player);
	MoveComp.ClearResolverExtensions(Instigator);
}

}