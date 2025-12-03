class USanctuaryLightableCandleComponent : UStaticMeshComponent
{
	FVector MinScale;
	FVector OriginalScale;

	float VisibleAlpha = 0.0;
	bool bLit = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetVisibility(false, true);
		OriginalScale = GetWorldScale();
		MinScale = OriginalScale;
		SetWorldScale3D(MinScale);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (IsVisible() && !bLit)
		{
			VisibleAlpha = Math::Clamp(VisibleAlpha + DeltaSeconds, 0.0, 1.0);
			SetWorldScale3D(Math::EaseOut(MinScale, OriginalScale, VisibleAlpha, 2.0));
			if (VisibleAlpha >= 1.0 - KINDA_SMALL_NUMBER)
				bLit = true;
		}
		else if (!IsVisible() && bLit)
		{
			VisibleAlpha = Math::Clamp(VisibleAlpha - DeltaSeconds, 0.0, 1.0);
			SetWorldScale3D(Math::EaseOut(MinScale, OriginalScale, VisibleAlpha, 2.0));
			if (VisibleAlpha <= KINDA_SMALL_NUMBER)
				bLit = false;
		}
	}
};