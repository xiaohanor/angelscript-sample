UCLASS(Meta = (HighlightPlacement))
class APlayerSprintVolume : AVolume
{
	default BrushColor = FLinearColor(0.1, 0.3, 0.8);
	default BrushComponent.LineThickness = 4.0;

	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly)
	const bool bForceSprint = true;

	UPROPERTY(Category = Settings, EditAnywhere, BlueprintReadOnly)
	ULocomotionFeatureSprint OptionalFeature;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		if (bForceSprint)
			Player.ForceSprint(this);

		if (OptionalFeature != nullptr)
			Player.AddLocomotionFeature(OptionalFeature, this);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
			
		if (bForceSprint)
			Player.ClearForceSprint(this);

		if (OptionalFeature != nullptr)
			Player.RemoveLocomotionFeature(OptionalFeature, this);
	}
}