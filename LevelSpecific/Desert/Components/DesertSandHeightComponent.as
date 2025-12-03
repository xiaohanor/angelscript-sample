class UDesertSandHeightComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	bool bFollowSandHeight = true;
	
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bFollowSandHeight"))
	float HeightOffset = 0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bFollowSandHeight"))
	float InterpSpeedUp = 6;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bFollowSandHeight"))
	float InterpSpeedDown = 3;

	UPROPERTY(EditAnywhere)
	ESandSharkLandscapeLevel LandscapeLevel;

	private TArray<UDesertSandHeightSampleComponent> SampleComponents;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!bFollowSandHeight)
			SetComponentTickEnabled(false);

		Owner.GetComponentsByClass(SampleComponents);

		for(auto SampleComponent : SampleComponents)
			SampleComponent.LandscapeLevel = LandscapeLevel;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bFollowSandHeight)
			FollowSandHeight(DeltaTime);
	}

	private void FollowSandHeight(float DeltaTime)
	{
		FVector Location = Owner.ActorLocation;
		const float TargetHeight = GetSandHeight() + HeightOffset;

		if(TargetHeight > Location.Z)
			Location.Z = Math::FInterpTo(Location.Z, GetSandHeight() + HeightOffset, DeltaTime, InterpSpeedUp);
		else
			Location.Z = Math::FInterpTo(Location.Z, GetSandHeight() + HeightOffset, DeltaTime, InterpSpeedDown);

		Owner.SetActorLocation(Location);
	}

	UFUNCTION(BlueprintPure)
	float GetSandHeight() const
	{
		float Height = 0;
		float TotalPriority = 0;
		for(auto SampleComponent : SampleComponents)
		{
			Height += SampleComponent.GetSandHeight() * SampleComponent.Priority;
			TotalPriority += SampleComponent.Priority;
		}

		return Height / TotalPriority;
	}
};