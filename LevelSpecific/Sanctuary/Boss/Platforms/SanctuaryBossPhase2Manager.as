struct FHydraPlatformManagerData
{
	UPROPERTY()
	FHydraPlatformData InData;

	UPROPERTY()
	ASanctuaryBossPlatformHydra HeadActor;
}

class ASanctuaryBossPhase2Manager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LoopingPlatformPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraPivotComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY()
	float PlatformSpeed = 0.0;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossLoopingPlatform> PlatformArray;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossLoopingPlatform MiddlePlatform;

	UPROPERTY(EditInstanceOnly)
	TArray<ASanctuaryBossPlatformHydra> HydraHeadArray;

	UPROPERTY(EditInstanceOnly)
	bool bUpdateSplineAndLinkHydras;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bUpdateSplineAndLinkHydras)
		{
			for (auto Hydra : HydraHeadArray)
			{
				Hydra.Manager = this;
			}

			for (auto Platform : PlatformArray)
			{
				Platform.Manager = this;
			}

			bUpdateSplineAndLinkHydras = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MiddlePlatform.bMiddlePlatform = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		LoopingPlatformPivotComp.AddRelativeRotation(FRotator(0.0, PlatformSpeed * DeltaSeconds, 0.0));

		CameraPivotComp.AddRelativeRotation(FRotator(0.0, DeltaSeconds * -10.0, 0.0));

		MiddlePlatform.AddActorLocalRotation(FRotator(PlatformSpeed * DeltaSeconds * 0.0, PlatformSpeed * DeltaSeconds, PlatformSpeed * DeltaSeconds));
	}

	UFUNCTION()
	void ProgressPointSetup(FRotator MiddlePlatformRotation, float CameraRotation, float PlatformRotation)
	{
		MiddlePlatform.SetActorRotation(MiddlePlatformRotation);
		CameraPivotComp.SetRelativeRotation(FRotator(0.0, CameraRotation, 0.0));
		LoopingPlatformPivotComp.SetRelativeRotation(FRotator(0.0, PlatformRotation, 0.0));
	}

	UFUNCTION()
	void PrintSettings()
	{
		PrintToScreenScaled("MiddlePlatformRotation = " + MiddlePlatform.ActorRotation, 20.0, FLinearColor::Yellow, 5.0);
		PrintToScreenScaled("CameraRotation = " + CameraPivotComp.RelativeRotation.Yaw, 20.0, FLinearColor::Yellow, 5.0);
		PrintToScreenScaled("PlatformRotation = " + LoopingPlatformPivotComp.RelativeRotation.Yaw, 20.0, FLinearColor::Yellow, 5.0);
	}
};