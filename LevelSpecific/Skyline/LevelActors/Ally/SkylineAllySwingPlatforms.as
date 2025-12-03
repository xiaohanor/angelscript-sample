class ASkylineAllySwingPlatforms : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UPerchPointComponent PerchPointComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	UPerchEnterByZoneComponent PerchEnterZoneComp;

	UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY()
	UHazeCameraSettingsDataAsset GrappleCameraSettings;

	UPROPERTY()
	bool bSwing = false;

	private bool bIsActiveLocal = false;
	private float GameTimeActivatedLocal = -1;
	private float GameTimeDeactivatedLocal = -1;
	private bool bSyncedIsActive = false;
	private bool bIsActiveRemote = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bSwing)
		{
			SwingPointComp.OnPlayerAttachedEvent.AddUFunction(this, n"HandleStartSwing");
			SwingPointComp.OnPlayerDetachedEvent.AddUFunction(this, n"HandleStopSwing");
			PerchPointComp.Disable(this);
		}
		else
		{
			PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"HandleStartPerching");
			PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"HandleStoppedPerching");
			SwingPointComp.Disable(this);
		}

		TranslateComp.OnConstraintHit.AddUFunction(this, n"OnConstrainHit");
	}

	UFUNCTION()
	private void OnConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();
	}

	UFUNCTION()
	private void HandleStartSwing(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		bIsActiveLocal = true;
		GameTimeActivatedLocal = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void HandleStopSwing(AHazePlayerCharacter Player, USwingPointComponent SwingPoint)
	{
		bIsActiveLocal = false;
		GameTimeDeactivatedLocal = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void HandleStartPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bIsActiveLocal = true;
		GameTimeActivatedLocal = Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void HandleStoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		bIsActiveLocal = false;
		GameTimeDeactivatedLocal = Time::GameTimeSeconds;
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetActive(bool bWorldControl, bool bActive)
	{
		if (bWorldControl == Network::HasWorldControl())
			return;
		bIsActiveRemote = bActive;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bLocalWantOutwardForce = false;
		if (bIsActiveLocal || (GameTimeDeactivatedLocal > 0 && Time::GetGameTimeSince(GameTimeDeactivatedLocal) < 0.5))
		{
			bLocalWantOutwardForce = true;
			if (!bSyncedIsActive)
			{
				CrumbSetActive(Network::HasWorldControl(), bIsActiveLocal);
				bSyncedIsActive = true;
			}
		}
		else
		{
			if (bSyncedIsActive)
			{
				CrumbSetActive(Network::HasWorldControl(), bIsActiveLocal);
				bSyncedIsActive = false;
			}
		}

		bool bFinalWantOutwardForce = false;
		if (Network::IsGameNetworked())
		{
			if (Game::Mio.HasControl())
			{
				// Mio's side immediately goes out when starting to perch, but waits for zoe's side before retracting
				if (bLocalWantOutwardForce || bIsActiveRemote)
					bFinalWantOutwardForce = true;
			}
			else
			{
				// Zoe's side calculates completely locally
				bFinalWantOutwardForce = bLocalWantOutwardForce;
			}
		}
		else
		{
			bFinalWantOutwardForce = bLocalWantOutwardForce;
		}

		if (bFinalWantOutwardForce)
			ForceComp.Force = FVector::ForwardVector * 3000.0;
		else
			ForceComp.Force = FVector::ForwardVector * -3000.0;
	}
};