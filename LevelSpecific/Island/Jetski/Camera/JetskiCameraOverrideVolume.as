UCLASS(NotBlueprintable)
class AJetskiCameraOverrideVolume : AVolume
{
	default BrushComponent.CollisionProfileName = n"TriggerOnlyPlayer";

	UPROPERTY(EditInstanceOnly)
	AJetskiCameraOverrideSpline CameraOverrideSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnActorEnter");
		OnActorEndOverlap.AddUFunction(this, n"OnActorLeave");
	}

	UFUNCTION()
	private void OnActorEnter(AActor OverlappedActor, AActor OtherActor)
	{
		auto Jetski = Cast<AJetski>(OtherActor);
		if(Jetski == nullptr)
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			Jetski = Jetski::GetJetski(Player);
		}

		if(Jetski == nullptr)
			return;

		Jetski.CameraOverrideSplines.Apply(CameraOverrideSpline, this);
	}

	UFUNCTION()
	private void OnActorLeave(AActor OverlappedActor, AActor OtherActor)
	{
		auto Jetski = Cast<AJetski>(OtherActor);
		if(Jetski == nullptr)
		{
			auto Player = Cast<AHazePlayerCharacter>(OtherActor);
			if(Player == nullptr)
				return;

			Jetski = Jetski::GetJetski(Player);
		}

		if(Jetski == nullptr)
			return;

		Jetski.CameraOverrideSplines.Clear(this);
	}
};