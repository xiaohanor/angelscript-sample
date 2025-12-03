class ASplitBonanzaLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	USceneComponent LineRoot;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	UStaticMeshComponent Line1;
	default Line1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Line1.TranslucencySortPriority = 1000;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	UStaticMeshComponent Line2;
	default Line2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Line2.TranslucencySortPriority = 1000;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	UStaticMeshComponent Line3;
	default Line3.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Line3.TranslucencySortPriority = 1000;

	UPROPERTY(DefaultComponent, Attach = LineRoot)
	UStaticMeshComponent Line4;
	default Line4.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default Line4.TranslucencySortPriority = 1000;

	UPROPERTY(DefaultComponent)
	USplitBonanzaLineComponent LineComponent;
	
	UPROPERTY(EditInstanceOnly)
	TArray<TSoftObjectPtr<UWorld>> AffectedLevels;

	// Size of the split in angles from the pivot
	UPROPERTY(EditAnywhere, Interp)
	EFakeSplitAreaType AreaType = EFakeSplitAreaType::Split;

	UPROPERTY(EditAnywhere, Interp, Meta = (EditCondition = "AreaType == EFakeSplitAreaType::Split || AreaType == EFakeSplitAreaType::CircleArc", EditConditionHides))
	float SplitAngularSize = 90.0;

	UPROPERTY(EditAnywhere, Interp, Meta = (EditCondition = "AreaType == EFakeSplitAreaType::CircleArc", EditConditionHides))
	float CircleRadius = 500.0;

	UPROPERTY(EditAnywhere, Interp, Meta = (EditCondition = "AreaType == EFakeSplitAreaType::Rectangle", EditConditionHides))
	FVector2D RectangleExtents = FVector2D(500.0, 500.0);

	UPROPERTY(EditAnywhere, Interp)
	float SplitZOrder = 0.0;

	UPROPERTY(EditAnywhere)
	bool bNeverCollideWithPlayer = false;

	UPROPERTY(EditAnywhere)
	bool bVisibleDuringIntroCutscene = false;

	UPROPERTY(EditAnywhere, Category = "Lighting")
	FSplitBonanzaLightingSettings LightingSettings;

	private TArray<FInstigator> RenderingBlockInstigators;
	bool bLineActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void UpdateLineShape()
	{
		if (AreaType == EFakeSplitAreaType::Split)
		{
			Line1.SetVisibility(true);
			Line1.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(10000.0, 0.0, 0.0),
					FVector(200.0, 0.4, 0.01),
				)
			);
			
			FRotator Line2Rotation = FRotator(0.0, SplitAngularSize, 0.0);

			Line2.SetVisibility(true);
			Line2.SetRelativeTransform(
				FTransform(
					Line2Rotation,
					Line2Rotation.RotateVector(FVector(10000.0, 0.0, 0.0)),
					FVector(200.0, 0.4, 0.01),
				)
			);

			Line3.SetVisibility(false);
			Line4.SetVisibility(false);
		}
		else if (AreaType == EFakeSplitAreaType::Rectangle)
		{
			Line1.SetVisibility(true);
			Line1.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(RectangleExtents.X / 2, 0.0, 0.0),
					FVector(RectangleExtents.X / 100 + 0.4, 0.4, 0.01),
				)
			);

			Line2.SetVisibility(true);
			Line2.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(0.0, RectangleExtents.Y / 2, 0.0),
					FVector(0.4, RectangleExtents.Y / 100 + 0.4, 0.01),
				)
			);

			Line3.SetVisibility(true);
			Line3.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(RectangleExtents.X / 2, RectangleExtents.Y, 0.0),
					FVector(RectangleExtents.X / 100 + 0.4, 0.4, 0.01),
				)
			);

			Line4.SetVisibility(true);
			Line4.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(RectangleExtents.X, RectangleExtents.Y / 2, 0.0),
					FVector(0.4, RectangleExtents.Y / 100 + 0.4, 0.01),
				)
			);
		}
		else if (AreaType == EFakeSplitAreaType::CircleArc)
		{
			Line1.SetVisibility(true);
			Line1.SetRelativeTransform(
				FTransform(
					FRotator(),
					FVector(),
					FVector(CircleRadius / 50 + 0.5, CircleRadius / 50 + 0.5, 0.01),
				)
			);

			Line2.SetVisibility(false);
			Line3.SetVisibility(false);
			Line4.SetVisibility(false);
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateLineShape();
	}
#endif

	FBox SplitLocalBoundingBox;

	FVector2D SplitScreenSpaceWideBoundsMin;
	FVector2D SplitScreenSpaceWideBoundsMax;

	FVector2D SplitScreenSpaceTightBoundsMin;
	FVector2D SplitScreenSpaceTightBoundsMax;

	void UpdateSplitBoundingBox()
	{
		SplitLocalBoundingBox = FBox();
		switch (AreaType)
		{
			case EFakeSplitAreaType::Split:
				SplitLocalBoundingBox += FVector(0, 0, 0);
				SplitLocalBoundingBox += FVector(10000, 10000, 0);
			break;
			case EFakeSplitAreaType::Rectangle:
				SplitLocalBoundingBox += FVector(0, 0, 0);
				SplitLocalBoundingBox += FVector(RectangleExtents.X, RectangleExtents.Y, 0);
			break;
			case EFakeSplitAreaType::CircleArc:
				SplitLocalBoundingBox += FVector(-CircleRadius, -CircleRadius, 0);
				SplitLocalBoundingBox += FVector(CircleRadius, CircleRadius, 0);
			break;
		}
	}

	UFUNCTION()
	void BlockRendering(FInstigator Instigator)
	{
		AddActorVisualsBlock(this);

		if (RenderingBlockInstigators.Num() == 0)
		{
			for (TSoftObjectPtr<UWorld> SoftLevel : AffectedLevels)
				SceneView::SetLevelRenderedForAnyView(SoftLevel, false);
		}

		RenderingBlockInstigators.AddUnique(Instigator);
	}

	UFUNCTION()
	void UnblockRendering(FInstigator Instigator)
	{
		bool bWasBlocked = RenderingBlockInstigators.Num() != 0;

		RenderingBlockInstigators.Remove(Instigator);
		RemoveActorVisualsBlock(this);

		if (RenderingBlockInstigators.Num() == 0 && bWasBlocked)
		{
			for (TSoftObjectPtr<UWorld> SoftLevel : AffectedLevels)
				SceneView::SetLevelRenderedForAnyView(SoftLevel, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateLineShape();

		// if (RenderingBlockInstigators.Num() == 0)
		// 	PrintToScreen(f"{ActorNameOrLabel} RENDERED / {SplitScreenSpaceWideBoundsMin} -> {SplitScreenSpaceWideBoundsMax} / {SplitScreenSpaceTightBoundsMin} -> {SplitScreenSpaceTightBoundsMax}", 0.0, ColorDebug::Leaf);
		// else
		// 	PrintToScreen(f"{ActorNameOrLabel} HIDDEN / {SplitScreenSpaceWideBoundsMin} -> {SplitScreenSpaceWideBoundsMax} / {SplitScreenSpaceTightBoundsMin} -> {SplitScreenSpaceTightBoundsMax}", 0.0, ColorDebug::Tangerine);
	}
};

class USplitBonanzaLineComponent : UHazeEditorRenderedComponent
{
#if EDITOR
	default bTickInEditor = true;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!GetWorld().IsGameWorld())
			MarkRenderStateDirty();
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void CalcBounds(FVector& OutOrigin, FVector& OutBoxExtent, float& OutSphereRadius) const
	{
		OutOrigin = WorldLocation;
		OutBoxExtent = FVector(1000000.0);
	}

	UFUNCTION(BlueprintOverride)
	void CreateEditorRenderState()
	{
		auto LineActor = Cast<ASplitBonanzaLine>(Owner);

		FVector SplitEndDirection = FQuat(FVector::UpVector, Math::DegreesToRadians(LineActor.SplitAngularSize)) * LineActor.ActorForwardVector;
		FVector SplitMiddleDirection = FQuat(FVector::UpVector, Math::DegreesToRadians(LineActor.SplitAngularSize * 0.5)) * LineActor.ActorForwardVector;
		FLinearColor SplitColor = FLinearColor::MakeFromHSV8(uint8((FName(LineActor.ActorNameOrLabel).Hash * 11111) % 255), 128, 255);

		switch (LineActor.AreaType)
		{
			case EFakeSplitAreaType::Split:
				DrawArc(
					LineActor.ActorLocation,
					LineActor.SplitAngularSize,
					500.0,
					SplitMiddleDirection,
					SplitColor,
					30.0,
				);
				DrawLine(
					LineActor.ActorLocation,
					LineActor.ActorLocation + LineActor.ActorForwardVector * 100000.0,
					SplitColor, 30.0
				);
				DrawLine(
					LineActor.ActorLocation,
					LineActor.ActorLocation + SplitEndDirection * 100000.0,
					SplitColor, 30.0
				);
			break;
			case EFakeSplitAreaType::Rectangle:
				DrawLine(
					LineActor.ActorLocation,
					LineActor.ActorLocation + LineActor.ActorForwardVector * LineActor.RectangleExtents.X,
					SplitColor, 30.0
				);

				DrawLine(
					LineActor.ActorLocation + LineActor.ActorRightVector * LineActor.RectangleExtents.Y,
					LineActor.ActorLocation + LineActor.ActorForwardVector * LineActor.RectangleExtents.X + LineActor.ActorRightVector * LineActor.RectangleExtents.Y,
					SplitColor, 30.0
				);

				DrawLine(
					LineActor.ActorLocation,
					LineActor.ActorLocation + LineActor.ActorRightVector * LineActor.RectangleExtents.Y,
					SplitColor, 30.0
				);

				DrawLine(
					LineActor.ActorLocation + LineActor.ActorForwardVector * LineActor.RectangleExtents.X,
					LineActor.ActorLocation + LineActor.ActorRightVector * LineActor.RectangleExtents.Y + LineActor.ActorForwardVector * LineActor.RectangleExtents.X,
					SplitColor, 30.0
				);
			break;
			case EFakeSplitAreaType::CircleArc:
				if (LineActor.SplitAngularSize < 360.0)
				{
					DrawArc(
						LineActor.ActorLocation,
						LineActor.SplitAngularSize,
						LineActor.CircleRadius,
						SplitMiddleDirection,
						SplitColor,
						30.0,
					);
				}
				else
				{
					DrawCircle(
						LineActor.ActorLocation,
						LineActor.CircleRadius,
						SplitColor,
						30.0,
					);
				}
			break;
		}

	}
#endif
};

struct FSplitBonanzaLightingSettings
{
	UPROPERTY()
	float Intensity = 1000.0;
	UPROPERTY()
	FLinearColor LightColor = FLinearColor::White;
	UPROPERTY()
	float AttenuationRadius = 20000.0;
	UPROPERTY()
	bool bUseTemperature = true;
	UPROPERTY()
	float Temperature = 5000.0;

	void BlendTowards(FSplitBonanzaLightingSettings Other, float DeltaTime, float InterpSpeed)
	{
		Intensity = Math::FInterpTo(Intensity, Other.Intensity, DeltaTime, InterpSpeed);
		AttenuationRadius = Math::FInterpTo(AttenuationRadius, Other.AttenuationRadius, DeltaTime, InterpSpeed);

		FVector MyColor(LightColor.R, LightColor.G, LightColor.B);
		FVector OtherColor(Other.LightColor.R, Other.LightColor.G, Other.LightColor.B);

		MyColor = Math::VInterpTo(MyColor, OtherColor, DeltaTime, InterpSpeed);
		LightColor.R = MyColor.X;
		LightColor.G = MyColor.Y;
		LightColor.B = MyColor.Z;

		if (Other.bUseTemperature)
		{
			if (!bUseTemperature)
			{
				Temperature = Other.Temperature;
				bUseTemperature = true;
			}

			Temperature = Math::FInterpTo(Temperature, Other.Temperature, DeltaTime, InterpSpeed);
		}
		else
		{
			bUseTemperature = false;
		}
	}

	void Apply(USpotLightComponent Light)
	{
		Light.SetIntensity(Intensity);
		Light.SetLightColor(LightColor);
		Light.SetAttenuationRadius(AttenuationRadius);
		Light.SetUseTemperature(bUseTemperature);
		Light.SetTemperature(Temperature);
	}
};
