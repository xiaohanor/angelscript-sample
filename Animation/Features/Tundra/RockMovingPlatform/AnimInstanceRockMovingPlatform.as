UCLASS(Abstract)
class UAnimInstanceRockMovingPlatform : UHazeAnimInstanceBase
{
	AEvergreenRockMovingPlatform Platform;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform Stem1Transform;

	UPROPERTY(Transient, BlueprintReadOnly, NotVisible)
	FTransform Stem5Transform;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if(OwningComponent == nullptr)
			return;

		Platform = Cast<AEvergreenRockMovingPlatform>(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		if(OwningComponent == nullptr)
			return;

		if(Platform == nullptr)
		{
			Platform = Cast<AEvergreenRockMovingPlatform>(OwningComponent.Owner);

			if(Platform == nullptr)
				return;
		}

		Stem1Transform = Platform.Stem1Transform;
		Stem5Transform = Platform.Stem5Transform;
	}
}