class UEnforcerDangerZone : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	float ShowTime = -1.0;

	float MinScale = 0.001;
	float MaxScale = 1.0;
	float ExpandDuration = 0.2;

	TArray<UPrimitiveComponent> AttachChildren;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetChildrenComponentsByClass(UPrimitiveComponent, true, AttachChildren);
		Hide();
	}

	void Update(float DeltaTime)
	{
		if (ShowTime == 0.0)
			return;	

		WorldRotation = FRotator::ZeroRotator;
		float Scale = Math::Lerp(MinScale, MaxScale, Math::Min(1.0, Time::GetGameTimeSince(ShowTime) / ExpandDuration));
		WorldScale3D = FVector(Scale);
	}

	UFUNCTION()
	void Show(float FullScale = 1.0, float ExpansionDuration = 0.3)
	{
		MaxScale = FullScale;
		ExpandDuration = ExpansionDuration;
		if (ShowTime > 0.0)
			return;

		ShowTime = Time::GameTimeSeconds;
		WorldScale3D = FVector(MinScale);
		RemoveComponentVisualsBlocker(this);
		for (UPrimitiveComponent Child : AttachChildren)
		{
			Child.RemoveComponentVisualsBlocker(this);
		}
	}

	UFUNCTION()
	void Hide()
	{	
		if (ShowTime == 0.0)
			return;

		ShowTime = 0.0;
		WorldScale3D = FVector(MinScale);
		AddComponentVisualsBlocker(this);
		for (UPrimitiveComponent Child : AttachChildren)
		{
			Child.AddComponentVisualsBlocker(this);
		}
	}
}

