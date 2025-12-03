class ACentipedeCrawlConstraintVolume : AActorTrigger
{
	default ActorClasses.Add(AHazePlayerCharacter);

#if EDITOR
	// default bDisplayShadedVolume = true;
	default ShadedVolumeOpacityValue = 0.1;
	default BrushComponent.LineThickness = 5.0;
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorEnter.AddUFunction(this, n"OnActorEnter");
		OnActorLeave.AddUFunction(this, n"OnActorLeave");
	}

	// Shitty because it hard pwns velocity, let's see how it works with multiple fellas
	FVector ConstrainLocation(FVector Location)
	{
		FVector _RelativeLocation = ActorTransform.InverseTransformPosition(Location);
		FVector BrushExtent = BrushComponent.ComponentLocalBoundingBox.Extent;

		FVector ConstrainedRelativeLocation = _RelativeLocation.ConstrainToDirection(FVector::ForwardVector).GetClampedToMaxSize(BrushExtent.X)
											+ _RelativeLocation.ConstrainToDirection(FVector::RightVector).GetClampedToMaxSize(BrushExtent.Y)
											+ _RelativeLocation.ConstrainToDirection(FVector::UpVector).GetClampedToMaxSize(BrushExtent.Z);

		return ActorTransform.TransformPosition(ConstrainedRelativeLocation);
	}

	bool IsLocationWithinConstraints(FVector WorldLocation) const
	{
		return Math::IsPointInBoxWithTransform(WorldLocation, ActorTransform, BrushComponent.ComponentLocalBoundingBox.Extent);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorEnter(AHazeActor Actor)
	{
		UPlayerCentipedeComponent PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Actor);
		if (PlayerCentipedeComponent != nullptr)
			PlayerCentipedeComponent.AddCrawlConstraint(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActorLeave(AHazeActor Actor)
	{
		UPlayerCentipedeComponent PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(Actor);
		if (PlayerCentipedeComponent != nullptr)
			PlayerCentipedeComponent.RemoveCrawlConstraint(this);
	}

	void DrawDebug() const
	{
#if EDITOR
		FLinearColor Color = FColor::FromHex("A6BC251A").ReinterpretAsLinear() * FLinearColor(1, 1, 1, 0.1);
		Debug::DrawDebugSolidBox(ActorLocation, BrushComponent.ComponentLocalBoundingBox.Extent * BrushComponent.GetWorldScale(), ActorRotation, Color);
#endif
	}
}