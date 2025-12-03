struct FDesertFloatingPlatformSettings
{
	UPROPERTY()
	float MaxX = 180.0;

	UPROPERTY()
	float XRate = 0.6;

	UPROPERTY()
	float MaxY = 120.0;

	UPROPERTY()
	float YRate = 0.9;

	UPROPERTY()
	float MaxZ = 60.0;

	UPROPERTY()
	float ZRate = 1.2;

	UPROPERTY()
	float YawRate = 10.0;

	UPROPERTY()
	float MaxRoll = 1.0;

	UPROPERTY()
	float RollRate = 1.5;

	UPROPERTY()
	float MaxPitch = 1.4;

	UPROPERTY()
	float PitchRate = 1.75;

	UPROPERTY()
	float Scalar = 1.0;
}

class ADesertFloatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	USceneComponent PlatformYawRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformYawRoot)
	USceneComponent PlatformPitchRollRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformPitchRollRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(EditAnywhere)
	FDesertFloatingPlatformSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float XOffset = Math::Sin(Time::GameTimeSeconds * Settings.XRate) * Settings.MaxX;
		float YOffset = Math::Sin(Time::GameTimeSeconds * Settings.YRate) * Settings.MaxY;
		float ZOffset = Math::Sin(Time::GameTimeSeconds * Settings.ZRate) * Settings.MaxZ;
		PlatformRoot.SetRelativeLocation(FVector(XOffset, YOffset, ZOffset));

		PlatformYawRoot.AddLocalRotation(FRotator(0.0, Settings.YawRate * DeltaTime, 0.0));

		float RollOffset = Math::Sin(Time::GameTimeSeconds * Settings.RollRate) * Settings.MaxRoll;
		float PitchOffset = Math::Sin(Time::GameTimeSeconds * Settings.PitchRate) * Settings.MaxRoll;

		PlatformPitchRollRoot.SetRelativeRotation(FRotator(PitchOffset, 0.0, RollOffset));
	}

	UFUNCTION(CallInEditor)
	void RandomizeValues()
	{
		FDesertFloatingPlatformSettings BaseSettings = FDesertFloatingPlatformSettings();
		Settings.MaxX = Math::RandRange(BaseSettings.MaxX/2, BaseSettings.MaxX) * Settings.Scalar;
		Settings.MaxY = Math::RandRange(BaseSettings.MaxY/2, BaseSettings.MaxY) * Settings.Scalar;
		Settings.MaxZ = Math::RandRange(BaseSettings.MaxZ/2, BaseSettings.MaxZ) * Settings.Scalar;

		Settings.XRate = Math::RandRange(BaseSettings.XRate/2, BaseSettings.XRate) * Settings.Scalar;
		Settings.YRate = Math::RandRange(BaseSettings.YRate/2, BaseSettings.YRate) * Settings.Scalar;
		Settings.ZRate = Math::RandRange(BaseSettings.ZRate/2, BaseSettings.ZRate) * Settings.Scalar;

		float YawRateModifier = Math::RandBool() ? 1.0 : -1.0;
		Settings.YawRate = Math::RandRange((BaseSettings.YawRate * YawRateModifier)/2, BaseSettings.YawRate * YawRateModifier) * Settings.Scalar;

		Settings.MaxRoll = Math::RandRange(BaseSettings.MaxRoll/2, BaseSettings.MaxRoll) * Settings.Scalar;
		Settings.RollRate = Math::RandRange(BaseSettings.RollRate/2, BaseSettings.RollRate) * Settings.Scalar;
		Settings.MaxPitch = Math::RandRange(BaseSettings.MaxPitch/2, BaseSettings.MaxPitch) * Settings.Scalar;
		Settings.PitchRate = Math::RandRange(BaseSettings.PitchRate/2, BaseSettings.PitchRate) * Settings.Scalar;
	}
}