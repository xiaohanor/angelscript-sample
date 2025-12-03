
class APlayerSwimmingCurrentVolume : AVolume
{
	default BrushColor = FLinearColor(0.0, 1.0, 0.5);
	default BrushComponent.LineThickness = 4.0;
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent)
	UArrowComponent CurrentDirection;
	default CurrentDirection.SetbAbsoluteScale(true);
	default CurrentDirection.SetRelativeScale3D(FVector(5.0, 5.0, 5.0));

	UPROPERTY(Category = Settings, EditAnywhere)
	float CurrentStrength = 1000.0;

	TPerPlayer<UPlayerSwimmingComponent> OverlappingSwimComps;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		UPlayerSwimmingComponent SwimComp = UPlayerSwimmingComponent::GetOrCreate(Player);
		OverlappingSwimComps[Player] = SwimComp;

		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		OverlappingSwimComps[Player] = nullptr;

		if (OverlappingSwimComps[Player.OtherPlayer] == nullptr)
			SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (!Player.HasControl())
				continue;

			if (OverlappingSwimComps[Player] == nullptr)
				continue;

			if (OverlappingSwimComps[Player].InstigatedSwimmingState.Get() != EPlayerSwimmingActiveState::Active)
				continue;

			Player.AddMovementImpulse(CurrentDirection.ForwardVector * CurrentStrength * DeltaTime);
		}
	}
}