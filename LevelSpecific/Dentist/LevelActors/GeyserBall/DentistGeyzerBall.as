UCLASS(Abstract)
class ADentistGeyserBall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BallRoot;

	UPROPERTY(EditInstanceOnly, Category = "Movement")
	float Height = 2000.0;

	UPROPERTY(EditInstanceOnly, Category = "Movement")
	float StartOffset = 0.0;

	UPROPERTY(EditAnywhere, Category = "Movement")
	FHazeTimeLike HeightTimeLike;
	default HeightTimeLike.UseSmoothCurveZeroToOne();
	default HeightTimeLike.bLoop = true;

	UPROPERTY(EditInstanceOnly, Category = "Water Surface")
	float WaterSurfaceHeight = 600;

	private bool bIsUnderWater = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HeightTimeLike.BindUpdate(this, n"HeightTimeLikeUpdate");

		if (StartOffset > 0.0)
			Timer::SetTimer(this, n"Activate", StartOffset);
		else
			Activate();
	}

	UFUNCTION()
	private void Activate()
	{
		HeightTimeLike.Play();
	}

	UFUNCTION()
	private void HeightTimeLikeUpdate(float CurrentValue)
	{
		const float CurrentHeight = Height * CurrentValue;
		FVector Location = FVector::UpVector * CurrentHeight;
		BallRoot.SetRelativeLocation(Location);

		if(bIsUnderWater && CurrentHeight > WaterSurfaceHeight)
		{
			FDentistGeyserBallJumpOutOfWaterEventData EventData;
			EventData.Location = GetWaterSurfaceLocation();
			UDentistGeyserBallEventHandler::Trigger_JumpOutOfWater(this, EventData);
			bIsUnderWater = false;
		}
		else if(!bIsUnderWater && CurrentHeight < WaterSurfaceHeight)
		{
			FDentistGeyserBallPlungeIntoWaterEventData EventData;
			EventData.Location = GetWaterSurfaceLocation();
			UDentistGeyserBallEventHandler::Trigger_PlungeIntoWater(this, EventData);
			bIsUnderWater = true;
		}
	}

	FVector GetWaterSurfaceLocation() const
	{
		return ActorTransform.TransformPosition(FVector(0, 0, WaterSurfaceHeight));
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugPlane(GetWaterSurfaceLocation(), FVector::UpVector, 500, 500, FLinearColor::LucBlue);
	}
#endif
};