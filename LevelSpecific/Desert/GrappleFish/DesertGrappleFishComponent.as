class UDesertGrappleFishComponent : UActorComponent
{
	ADesertGrappleFish GrappleFish;

	private bool bHasUnconsumedDiveBreachEvent = false;
	private bool bHasUnconsumedResurfaceBreachEvent = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GrappleFish = Cast<ADesertGrappleFish>(Owner);
	}

	void OnAnimDiveBreachSurface()
	{
		bHasUnconsumedDiveBreachEvent = true;
	}

	void OnAnimResurfaceBreach()
	{
		bHasUnconsumedResurfaceBreachEvent = true;
	}

	void ConsumeDiveBreach()
	{
		bHasUnconsumedDiveBreachEvent = false;
	}

	void ConsumeResurfaceBreach()
	{
		bHasUnconsumedResurfaceBreachEvent = false;
	}

	bool HasDiveBreachedSand() const
	{
		return bHasUnconsumedDiveBreachEvent;
	}

	bool HasResurfaceBreachedSand() const
	{
		return bHasUnconsumedResurfaceBreachEvent;
	}
};