UCLASS(Abstract)
class UFlyingCarRifleHitMarkerWidget : UHazeUserWidget
{
	const float MaxDuration = 0.3;

	private float ActiveDuration = 0.0;

	void Setup(FHitResult HitResult)
	{
		AttachWidgetToActor(HitResult.Actor);

		FVector RelativeHitLocation = HitResult.Actor.ActorRelativeTransform.InverseTransformPosition(HitResult.ImpactPoint);
		SetWidgetRelativeAttachOffset(RelativeHitLocation);

		// I dunno, looks kinda cool
		float Hax = 10;
		FVector2D Offset = FVector2D(Math::RandRange(-Hax, Hax), Math::RandRange(-Hax, Hax));
		RenderTranslation = Offset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		// Update opacity
		float Alpha = Math::Abs(ActiveDuration / MaxDuration);
		float Opacity = 1.0 - Math::Pow(Alpha, 5);
		SetRenderOpacity(Opacity);

		// Update active time
		ActiveDuration += DeltaTime;
	}

	bool IsDuePwnage() const
	{
		return ActiveDuration >= MaxDuration;
	}
}