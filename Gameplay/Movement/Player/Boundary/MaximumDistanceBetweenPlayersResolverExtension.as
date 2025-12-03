class UMaximumDistanceBetweenPlayersResolverExtension : UMovementResolverExtension
{
	default SupportedResolverClasses.Add(USimpleMovementResolver);
	default SupportedResolverClasses.Add(USteppingMovementResolver);
	default SupportedResolverClasses.Add(USweepingMovementResolver);
	default SupportedResolverClasses.Add(UTeleportingMovementResolver);
	
	UBaseMovementResolver Resolver;
	FMaximumDistanceBetweenPlayersSettings Settings;

#if EDITOR
	void CopyFrom(const UMovementResolverExtension OtherBase) override
	{
		auto Other = Cast<UMaximumDistanceBetweenPlayersResolverExtension>(OtherBase);
		Resolver = Other.Resolver;
		Settings = Other.Settings;
	}
#endif

	void PrepareExtension(UBaseMovementResolver InResolver, const UBaseMovementData InMoveData) override
	{
		Super::PrepareExtension(InResolver, InMoveData);
		
		Resolver = Cast<UBaseMovementResolver>(InResolver);

		auto MaxDistanceComp = UMaximumDistanceBetweenPlayersComponent::Get(Resolver.Owner);
		if (MaxDistanceComp != nullptr)
			Settings = MaxDistanceComp.Settings.Get();
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

		FVector OtherPlayerLocation = Player.OtherPlayer.ActorLocation + Settings.OtherPlayerWorldSpaceOffset;
		FVector TargetLocation = CurrentLocation + OriginalDelta.Delta;

		FVector OriginalRelevantDifference = (CurrentLocation - OtherPlayerLocation);
		FVector TargetRelevantDifference = (TargetLocation - OtherPlayerLocation);
		FVector TargetIrrelevantDifference = FVector::ZeroVector;

		FVector RelevantVelocity = OriginalDelta.Velocity;
		FVector IrrelevantVelocity = FVector::ZeroVector;

		if (Settings.bOnlyLimitHorizontal)
		{
			OriginalRelevantDifference = OriginalRelevantDifference.VectorPlaneProject(WorldUp);

			TargetIrrelevantDifference = TargetRelevantDifference.ProjectOnToNormal(WorldUp);
			TargetRelevantDifference = TargetRelevantDifference.VectorPlaneProject(WorldUp);

			IrrelevantVelocity = RelevantVelocity.ProjectOnToNormal(WorldUp);
			RelevantVelocity = RelevantVelocity.VectorPlaneProject(WorldUp);
		}

		float RelevantDistance = TargetRelevantDifference.Size();
		if (RelevantDistance > Settings.MaximumDistance)
		{
			FVector ClampedTargetRelevantDifference = TargetRelevantDifference.GetClampedToMaxSize(Math::Max(Settings.MaximumDistance, OriginalRelevantDifference.Size()));
			FVector ClampedTargetLocation = OtherPlayerLocation + ClampedTargetRelevantDifference + TargetIrrelevantDifference;

			FVector WantedDelta = ClampedTargetLocation - CurrentLocation;
			NewDelta.Delta = WantedDelta;
			NewDelta.Velocity = OriginalDelta.Velocity;
			return true;
		}

		return false;
	}
}

class UMaximumDistanceBetweenPlayersComponent : UActorComponent
{
	TInstigated<FMaximumDistanceBetweenPlayersSettings> Settings;
}

struct FMaximumDistanceBetweenPlayersSettings
{
	// Maximum distance we allow the players to be from each other before preventing them from moving further
	UPROPERTY()
	float MaximumDistance = 1000.0;

	// Whether to only limit, and allow vertical distance to be free
	UPROPERTY()
	bool bOnlyLimitHorizontal = true;

	// Extra offset to apply to the other player's position before doing the maximum distance restriction
	UPROPERTY(AdvancedDisplay)
	FVector OtherPlayerWorldSpaceOffset;
}

namespace Boundary
{

UFUNCTION(Category = "Player|Movement")
void ApplyMovementMaximumDistanceBetweenPlayers(AHazePlayerCharacter Player, FMaximumDistanceBetweenPlayersSettings Settings, FInstigator Instigator)
{
	auto Comp = UMaximumDistanceBetweenPlayersComponent::GetOrCreate(Player);
	Comp.Settings.Apply(Settings, Instigator);

	auto MoveComp = UHazeMovementComponent::Get(Player);
	MoveComp.ApplyResolverExtension(UMaximumDistanceBetweenPlayersResolverExtension, Instigator);
}

UFUNCTION(Category = "Player|Movement")
void ClearMovementMaximumDistanceBetweenPlayers(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto Comp = UMaximumDistanceBetweenPlayersComponent::GetOrCreate(Player);
	Comp.Settings.Clear(Instigator);

	auto MoveComp = UHazeMovementComponent::Get(Player);
	MoveComp.ClearResolverExtensions(Instigator);
}

}