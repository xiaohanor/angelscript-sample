UCLASS(NotBlueprintable, HideCategories = "Rendering ComponentTick Disable Debug Activation Cooking Tags Physics LOD Collision")
class UPirateWaterSampleComponent : USceneComponent
{
	UPROPERTY(EditDefaultsOnly)
	int Index = -1;

	UPROPERTY(EditDefaultsOnly)
	bool bSampleNormalForSplash = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSampleNormalForSplash"))
	FVector SplashOffset = FVector::ZeroVector;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSampleNormalForSplash"))
	FRotator SplashDeckForward = FRotator::ZeroRotator;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSampleNormalForSplash"))
	FRotator SplashRotation = FRotator::ZeroRotator;

	private float LastSplashTime = 0;

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(OceanWaves::HasOceanWavePaint())
			OceanWaves::RemoveWaveDataInstigator(GetWaveInstigator());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bSampleNormalForSplash)
			return;

		if(Time::GetGameTimeSince(LastSplashTime) > Pirate::Ship::FrontSplashResetTime)
		{
			auto HazeOwner = Cast<AHazeActor>(Owner);
			FVector ShipVelocity = HazeOwner.ActorVelocity;

			if(ShipVelocity.Z > 0)
				return;

			OceanWaves::RequestWaveData(GetWaveInstigator(), WorldLocation);
			FVector WaterNormal = OceanWaves::GetLatestWaveData(GetWaveInstigator()).PointOnWaveNormal;
			const FVector HorizontalWaterNormal = WaterNormal.GetSafeNormal2D();
			FVector ShipForward = HazeOwner.ActorForwardVector;

			float SpeedInForwardDir = ShipVelocity.DotProduct(ShipForward);
			float SpeedAgainstWater = ShipVelocity.DotProduct(-HorizontalWaterNormal);

			const float WaterNormalValue = HorizontalWaterNormal.DotProduct(GetSplashDeckForward());

			// If the wave normal is going against the ship hull, and we are fast enough, spawn splash
			if(WaterNormalValue < Pirate::Ship::FrontSplashThreshold && SpeedInForwardDir > Pirate::Ship::FrontSplashMinimumSpeed && SpeedAgainstWater > Pirate::Ship::FrontSplashMinimumSpeed)
			{
				FPirateShipHitWaveEventData EventData;
				EventData.ForwardSpeed = SpeedInForwardDir;
				EventData.HullNormalSpeed = SpeedAgainstWater;
				EventData.Location = GetSplashLocation();
				EventData.Rotation = GetSplashRotation().Rotator();
				UPirateShipEventHandler::Trigger_HitWave(HazeOwner, EventData);
				//UPirateEnemySloopEventHandler::Trigger_HitWave(HazeOwner, EventData);
				LastSplashTime = Time::GameTimeSeconds;
			}
		}
	}

	FInstigator GetWaveInstigator() const
	{
		return FInstigator(this, Owner.Name);
	}

	float CalculateWaveHeight() const
	{
		auto Instigator = GetWaveInstigator();

		OceanWaves::RequestWaveData(Instigator, WorldLocation);

		if(OceanWaves::IsWaveDataReady(Instigator))
		{
			return OceanWaves::GetLatestWaveData(Instigator).PointOnWave.Z;
		}
		else
			return 0;
	}

	FVector SampleWaterLocation() const
	{
		float WaveHeight = CalculateWaveHeight();
		return FVector(WorldLocation.X, WorldLocation.Y, WaveHeight);
	}

	FVector GetSplashLocation() const
	{
		return WorldTransform.TransformPosition(SplashOffset);
	}

	FQuat GetSplashRotation() const
	{
		return Owner.ActorTransform.TransformRotation(SplashRotation.Quaternion());
	}

	FVector GetSplashDeckForward() const
	{
		return Owner.ActorTransform.TransformRotation(SplashDeckForward).ForwardVector;
	}

	int opCmp(UPirateWaterSampleComponent Other) const
	{
		if(Index > Other.Index)
			return 1;
		else if(Index < Other.Index)
			return -1;

		return 0;
	}
};

#if EDITOR
class UPirateWaterSampleComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UPirateWaterSampleComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto WaterSampleComp = Cast<UPirateWaterSampleComponent>(Component);
		if(WaterSampleComp == nullptr)
			return;

		FVector Location = WaterSampleComp.WorldLocation;
		DrawPoint(Location, FLinearColor::LucBlue, 20);

		if(WaterSampleComp.bSampleNormalForSplash)
		{
			const FVector SplashLocation = WaterSampleComp.GetSplashLocation();
			DrawArrow(SplashLocation, SplashLocation + WaterSampleComp.GetSplashRotation().UpVector * 500, FLinearColor::Blue, 20, 3, true);
			DrawArrow(SplashLocation, SplashLocation + WaterSampleComp.GetSplashDeckForward() * 500, FLinearColor::Red, 20, 3, true);
		}
	}
};
#endif