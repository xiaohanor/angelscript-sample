class UPlayerAdditiveHitReactionComponent : UActorComponent
{
	AHazePlayerCharacter Player = nullptr;
	EHazeCardinalDirection HitDirection = EHazeCardinalDirection::Backward;
	EPlayerAdditiveHitReactionType HitType = EPlayerAdditiveHitReactionType::None;
	uint HitFrame;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION()
	void ApplyHitReaction(FVector WorldDirection, EPlayerAdditiveHitReactionType Type = EPlayerAdditiveHitReactionType::Small)
	{
		HitDirection = CardinalDirectionForActor(Player, WorldDirection);
		HitType = Type;
		HitFrame = GFrameNumber;
	}
};