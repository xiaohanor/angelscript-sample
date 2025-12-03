event void FTrashCompactorEvent();

UCLASS(Abstract)
class ATrashCompactor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CrusherRoot;

	UPROPERTY(DefaultComponent, Attach = CrusherRoot)
	USceneComponent LeftCrusherRoot;

	UPROPERTY(DefaultComponent, Attach = LeftCrusherRoot)
	UStaticMeshComponent LeftFrontMagneticPad;

	UPROPERTY(DefaultComponent, Attach = LeftCrusherRoot)
	UStaticMeshComponent LeftBackMagneticPad;

	UPROPERTY(DefaultComponent, Attach = LeftCrusherRoot)
	USceneComponent LeftFrontHatchRoot;

	UPROPERTY(DefaultComponent, Attach = LeftCrusherRoot)
	USceneComponent LeftBackHatchRoot;

	UPROPERTY(DefaultComponent, Attach = CrusherRoot)
	USceneComponent RightCrusherRotatedRoot;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRotatedRoot)
	USceneComponent RightCrusherRoot;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRoot)
	UStaticMeshComponent RightFrontMagneticPad;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRoot)
	UStaticMeshComponent RightBackMagneticPad;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRoot)
	USceneComponent RightFrontHatchRoot;

	UPROPERTY(DefaultComponent, Attach = RightCrusherRoot)
	USceneComponent RightBackHatchRoot;

	UPROPERTY(DefaultComponent)
	UMagneticFieldResponseComponent MagneticFieldComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedOffset;
	default SyncedOffset.SyncRate = EHazeCrumbSyncRate::Low;

	UPROPERTY(EditAnywhere)
	bool bPreview = false;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ZoeCamSettings;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealCrushersTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike FinalCrushTimeLike;

	UPROPERTY()
	FTrashCompactorEvent OnFinalCrush;

	float CrushStrength = 0.0;
	bool bCrushing = false;
	bool bFinalCrushActive = false;

	bool bBursted = false;

	float CrushSpeed = 160.0;
	float SpeedIncrease = 20.0;

	float StartHorizontalOffset = -2050.0;
	float EndHorizontalOffset = -1045.0;

	TArray<USceneComponent> Hatches;
	USceneComponent CurrentHatch;
	int HatchIndex = 0;
	bool bHatchOpen = false;

	TArray<UStaticMeshComponent> MagnetPads;
	UStaticMeshComponent CurrentMagnetPad;

	UPROPERTY(BlueprintReadOnly)
	float CrushAlpha = 0.0;

	float MaxOffset = -1050.0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		float Offset = bPreview ? EndHorizontalOffset : StartHorizontalOffset;
		LeftCrusherRoot.SetRelativeLocation(FVector(0.0, Offset, 0.0));
		RightCrusherRoot.SetRelativeLocation(FVector(0.0, Offset, 0.0));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FinalCrushTimeLike.BindUpdate(this, n"UpdateFinalCrush");
		FinalCrushTimeLike.BindFinished(this, n"FinishFinalCrush");

		RevealCrushersTimeLike.BindUpdate(this, n"UpdateReveal");
		RevealCrushersTimeLike.BindFinished(this, n"FinishReveal");

		OpenHatchTimeLike.BindUpdate(this, n"UpdateOpenHatch");
		OpenHatchTimeLike.BindFinished(this, n"FinishOpenHatch");

		SetActorControlSide(Game::Zoe);

		MagneticFieldComp.OnBurst.AddUFunction(this, n"Burst");

		Hatches.Add(LeftFrontHatchRoot);
		Hatches.Add(RightBackHatchRoot);
		Hatches.Add(RightFrontHatchRoot);
		Hatches.Add(LeftBackHatchRoot);
		CurrentHatch = Hatches[0];

		MagnetPads.Add(LeftFrontMagneticPad);
		MagnetPads.Add(RightBackMagneticPad);
		MagnetPads.Add(RightFrontMagneticPad);
		MagnetPads.Add(LeftBackMagneticPad);
		CurrentMagnetPad = MagnetPads[0];
	}

	UFUNCTION(CrumbFunction)
	void CrumbOpenHatch()
	{
		OpenHatch();
	}

	void OpenHatch()
	{
		if (bHatchOpen)
			return;

		bHatchOpen = true;

		CurrentHatch = Hatches[HatchIndex];
		CurrentMagnetPad = MagnetPads[HatchIndex];

		OpenHatchTimeLike.PlayFromStart();

		BP_OpenHatch(HatchIndex);

		FTrashCompactorHatchParams Params;
		Params.HatchRoot = CurrentHatch;
		Params.HatchIndex = HatchIndex;
		
		UTrashCompactorEffectEventHandler::Trigger_OpenHatch(this, Params);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenHatch(int Index) {}

	void CloseHatch()
	{
		if (!bHatchOpen)
			return;

		bHatchOpen = false;

		OpenHatchTimeLike.ReverseFromEnd();

		BP_CloseHatch();

		FTrashCompactorHatchParams Params;
		Params.HatchIndex = HatchIndex;

		UTrashCompactorEffectEventHandler::Trigger_CloseHatch(this, Params);
		
		HatchIndex++;
		if (HatchIndex > 3)
			HatchIndex = 0;
	}

	UFUNCTION(BlueprintEvent)
	void BP_CloseHatch() {}

	UFUNCTION()
	private void UpdateOpenHatch(float CurValue)
	{
		float Offset = Math::Lerp(500.0, -50.0, CurValue);
		CurrentHatch.SetRelativeLocation(FVector(CurrentHatch.RelativeLocation.X, Offset, 0.0));
	}

	UFUNCTION()
	private void FinishOpenHatch()
	{

	}

	UFUNCTION()
	private void Burst(FMagneticFieldData Data)
	{
		if (bBursted)
			return;

		if (!Game::Zoe.HasControl())
			return;

		FVector DirFromMagnetPadToPlayer = (Game::Zoe.ActorLocation - CurrentMagnetPad.WorldLocation).GetSafeNormal();
		float Dot = DirFromMagnetPadToPlayer.DotProduct(FVector::DownVector);

		if (Dot >= 0.8)
			CrumbCloseHatch();
	}

	UFUNCTION(CrumbFunction)
	void CrumbCloseHatch()
	{
		bBursted = true;
		CloseHatch();

		UTrashCompactorEffectEventHandler::Trigger_PushedByMagnet(this);
	}

	UFUNCTION(BlueprintCallable)
	void RevealCrusher()
	{
		if (HasControl())
			CrumbRevealCrusher();
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbRevealCrusher()
	{
		RevealCrushersTimeLike.PlayFromStart();
		BP_RevealCrusher();

		Game::Zoe.ApplyCameraSettings(ZoeCamSettings, 3.0, this, EHazeCameraPriority::High);

		UTrashCompactorEffectEventHandler::Trigger_RevealCrusher(this);
	}

	UFUNCTION(BlueprintEvent)
	void BP_RevealCrusher() {}

	UFUNCTION(NotBlueprintCallable)
	void UpdateReveal(float CurValue)
	{
		float HoriOffset = Math::Lerp(StartHorizontalOffset, EndHorizontalOffset, CurValue);
		LeftCrusherRoot.SetRelativeLocation(FVector(0.0, HoriOffset, 0.0));
		RightCrusherRoot.SetRelativeLocation(FVector(0.0, HoriOffset, 0.0));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishReveal()
	{
		StartCrushing();

		UTrashCompactorEffectEventHandler::Trigger_FullyRevealed(this);
	}

	UFUNCTION(BlueprintCallable, DevFunction)
	void StartCrushing()
	{
		if (HasControl())
			CrumbStartCrushing();
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbStartCrushing()
	{
		bCrushing = true;
		SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::Standard);
		OpenHatch();

		UTrashCompactorEffectEventHandler::Trigger_StartCrushing(this);
	}

	UFUNCTION(BlueprintCallable)
	void StopCrushing()
	{
		if (HasControl())
			CrumbStopCrushing();
	}

	UFUNCTION(NotBlueprintCallable, CrumbFunction)
	private void CrumbStopCrushing()
	{
		bCrushing = false;
		SyncedOffset.OverrideSyncRate(EHazeCrumbSyncRate::Low);

		Game::Zoe.ClearCameraSettingsByInstigator(this);

		CloseHatch();

		UTrashCompactorEffectEventHandler::Trigger_StopCrushing(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bCrushing)
			return;

		if (bFinalCrushActive)
			return;

		if (HasControl())
		{
			if (bBursted)
			{
				float NewHeight = Math::FInterpTo(SyncedOffset.Value, 0.0, DeltaTime, 6.0);
				SyncedOffset.SetValue(NewHeight);

				if (Math::IsNearlyEqual(NewHeight, 0.0, 50.0))
					CrumbReturnedToStart();
			}
			else
			{
				float DistToPlayer = CurrentHatch.WorldLocation.Distance(Game::Zoe.ActorLocation);
				float Speed = DistToPlayer >= 1100.0 ? CrushSpeed : CrushSpeed * 0.65;

				const float NewOffset = SyncedOffset.Value - (Speed * DeltaTime);
				SyncedOffset.SetValue(Math::Clamp(NewOffset, MaxOffset, 0.0));

				if (SyncedOffset.Value <= -450.0 && !bHatchOpen)
				{
					CrumbOpenHatch();
				}

				if (SyncedOffset.Value <= MaxOffset)
					CrumbFinalCrush();
			}

			CrusherRoot.SetRelativeLocation(FVector(0.0, 0.0, SyncedOffset.Value));
		}
		else
		{
			CrusherRoot.SetRelativeLocation(FVector(0, 0, SyncedOffset.Value));
		}

		CrushAlpha = Math::GetMappedRangeValueClamped(FVector2D(0.0, MaxOffset), FVector2D(0.0, 1.0), SyncedOffset.Value);
		float CameraFraction = Math::Lerp(1.0, 0.0, CrushAlpha);

		Game::Zoe.ApplyManualFractionToCameraSettings(CameraFraction, this);
	}

	UFUNCTION(CrumbFunction)
	void CrumbReturnedToStart()
	{
		bBursted = false;
		CrushSpeed += SpeedIncrease;

		UTrashCompactorEffectEventHandler::Trigger_StartCrushing(this);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbFinalCrush()
	{
		if (bFinalCrushActive)
			return;

		bFinalCrushActive = true;

		FinalCrushTimeLike.PlayFromStart();
		OnFinalCrush.Broadcast();

		UTrashCompactorEffectEventHandler::Trigger_StartFinalCrush(this);
	}

	UFUNCTION(NotBlueprintCallable)
	private void UpdateFinalCrush(float CurValue)
	{
		float CurOffset = Math::Lerp(SyncedOffset.Value, -1400.0, CurValue);
		CrusherRoot.SetRelativeLocation(FVector(0.0, 0.0, CurOffset));
	}

	UFUNCTION(NotBlueprintCallable)
	private void FinishFinalCrush()
	{
	}
}