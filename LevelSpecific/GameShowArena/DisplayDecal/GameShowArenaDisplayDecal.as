struct FGameShowArenaDisplayDecalScaleParams
{
	UPROPERTY()
	float MinScale = 1.0;

	UPROPERTY()
	float MaxScale = 1.0;

	UPROPERTY()
	float MinDecalSize = 0;

	UPROPERTY()
	float MaxDecalSize = 150;

	UPROPERTY()
	float MinDecalOpacity = 80;

	UPROPERTY()
	float MaxDecalOpacity = 120;

	UPROPERTY()
	float PulsesPerSecond = 0.5;
}

struct FGameShowArenaDisplayDecalRotateParams
{
	UPROPERTY()
	float RotationAmountPerSecond = 360;
}

class UGameShowArenaDisplayDecalRotationCapability : UHazeCapability
{
	AGameShowArenaDisplayDecal DisplayDecal;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DisplayDecal = Cast<AGameShowArenaDisplayDecal>(Owner);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DisplayDecal.bIsRotatingDecal)
			return false;

		return true;
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DisplayDecal.bIsRotatingDecal)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DisplayDecal.SetActorRotation(Math::RotatorFromAxisAndAngle(DisplayDecal.ActorUpVector, DisplayDecal.RotationParams.RotationAmountPerSecond * Time::GameTimeSeconds));
	}
}

class UGameShowArenaDisplayDecalPulsingCapability : UHazeCapability
{
	AGameShowArenaDisplayDecal DisplayDecal;
	// float PulsesPerSecond = 1;
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DisplayDecal = Cast<AGameShowArenaDisplayDecal>(Owner);
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!DisplayDecal.bIsPulsingDecal)
			return false;

		return true;
	}
	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!DisplayDecal.bIsPulsingDecal)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Pulse = Math::MakePulsatingValue(Time::GameTimeSeconds, DisplayDecal.PulseParams.PulsesPerSecond);
		float Scale = Math::Lerp(DisplayDecal.PulseParams.MinScale, DisplayDecal.PulseParams.MaxScale, Pulse);
		float Size = Math::Lerp(DisplayDecal.PulseParams.MinDecalSize, DisplayDecal.PulseParams.MaxDecalSize, Pulse);
		float Opacity = Math::Lerp(DisplayDecal.PulseParams.MinDecalOpacity, DisplayDecal.PulseParams.MaxDecalOpacity, Pulse);

		DisplayDecal.DecalSize = Size;
		DisplayDecal.DecalOpacity = Opacity;
		DisplayDecal.SetActorScale3D(FVector::OneVector * Scale);
	}
}

class AGameShowArenaDisplayDecal : AGameShowArenaDynamicObstacleBase
{
	// UPROPERTY(EditAnywhere)
	// TArray<ABombToss_Platform> TargetPlatforms;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaDisplayDecalPulsingCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"GameShowArenaDisplayDecalRotationCapability");

	UPROPERTY(EditAnywhere)
	UTexture2D Texture;

	UPROPERTY(EditAnywhere)
	FLinearColor Tint = FLinearColor::Green;

	/** Currently we use box overlap to only change material params on overlapped platforms */
	UPROPERTY(DefaultComponent)
	UBoxComponent Box;
	default Box.bHiddenInGame = true;
	default Box.SetBoxExtent(FVector(100, 100, 100));
	default Box.SetCollisionProfileName(n"OverlapAllDynamic", true);

	UPROPERTY(EditAnywhere)
	bool bIsRotatingDecal;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsRotatingDecal"))
	FGameShowArenaDisplayDecalRotateParams RotationParams;

	UPROPERTY(EditAnywhere)
	bool bIsPulsingDecal;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "bIsPulsingDecal"))
	FGameShowArenaDisplayDecalScaleParams PulseParams;

	TArray<UGameShowArenaDisplayDecalPlatformComponent> PreviouslyOverlappedDisplayComps;

	UPROPERTY()
	float DecalSize = 150;

	UPROPERTY()
	float DecalOpacity = 100;

	UPROPERTY()
	bool bIsAlternateDecal = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Box.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxBeginOverlap");
		// Box.OnComponentBeginOverlap.AddUFunction(this, n"OnBoxEndOverlap");
		Box.QueueComponentForUpdateOverlaps();
		TArray<AActor> OverlappingActors;
		Box.GetOverlappingActors(OverlappingActors);
		for (auto Platform : OverlappingActors)
		{
			auto DisplayComp = UGameShowArenaDisplayDecalPlatformComponent::Get(Platform);
			if (DisplayComp == nullptr)
				continue;

			DisplayComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(ActorRotation, ActorLocation, FVector::OneVector * DecalSize), Texture, DecalColor = Tint), bIsAlternateDecal);
		}

		// if (!bIsRotatingDecal && !bIsPulsingDecal)
		// 	SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		for (auto DisplayComp : PreviouslyOverlappedDisplayComps)
		{
			DisplayComp.ClearMaterialParameters(bIsAlternateDecal);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TArray<AActor> NewOverlaps;
		Box.GetOverlappingActors(NewOverlaps);

		TArray<UGameShowArenaDisplayDecalPlatformComponent> OverlappedDisplayComps;
		for (auto Overlap : NewOverlaps)
		{
			auto DisplayComp = UGameShowArenaDisplayDecalPlatformComponent::Get(Overlap);
			if (DisplayComp == nullptr)
				continue;

			DisplayComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(ActorRotation, ActorLocation, FVector::OneVector * DecalSize), Texture, DecalOpacity, DecalColor = Tint), bIsAlternateDecal);
			OverlappedDisplayComps.AddUnique(DisplayComp);
		}

		for (auto DisplayComp : PreviouslyOverlappedDisplayComps)
		{
			if (OverlappedDisplayComps.Contains(DisplayComp))
				continue;

			DisplayComp.UpdateMaterialParameters(FGameShowArenaDisplayDecalParams(FTransform(ActorRotation, ActorLocation, FVector::OneVector * DecalSize), Texture, DecalOpacity = 0), bIsAlternateDecal);
		}
		PreviouslyOverlappedDisplayComps = OverlappedDisplayComps;
	}
}