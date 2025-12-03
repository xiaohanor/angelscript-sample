UCLASS(HideCategories = "Navigation Collision Rendering Debug Actor Cooking", Meta = (HighlightPlacement))
class AAnimationFeatureVolume : AVolume
{
	UPROPERTY(EditAnywhere)
	TArray<UHazeLocomotionFeatureBase> FeaturesZoe;

	UPROPERTY(EditAnywhere)
	TArray<UHazeLocomotionFeatureBase> FeaturesMio;

	UPROPERTY(EditAnywhere)
	int Prio = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player.IsMio())
			{
				for (auto Feature : FeaturesMio)
					Player.AddLocomotionFeature(Feature, this, Prio);
			}
			else
			{
				for (auto Feature : FeaturesZoe)
					Player.AddLocomotionFeature(Feature, this, Prio);
			}
		}
	}

	UFUNCTION()
	void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			if (Player.IsMio())
			{
				for (auto Feature : FeaturesMio)
					Player.RemoveLocomotionFeature(Feature, this);
			}
			else
			{
				for (auto Feature : FeaturesZoe)
					Player.RemoveLocomotionFeature(Feature, this);
			}
		}
	}
}