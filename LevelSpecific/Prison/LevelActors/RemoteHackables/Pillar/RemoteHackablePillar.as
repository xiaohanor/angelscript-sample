class ARemoteHackablePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PillarRoot;

	UPROPERTY(DefaultComponent, Attach = PillarRoot)
	USceneComponent PillarTop;

	UPROPERTY(DefaultComponent, Attach = PillarTop)
	USceneComponent HackableRoot;

	UPROPERTY(DefaultComponent, Attach = HackableRoot)
	URemoteHackingResponseComponent HackComp;

	UPROPERTY(DefaultComponent, Attach = PillarTop)
	USceneComponent TopHinge1;

	UPROPERTY(DefaultComponent, Attach = PillarTop)
	USceneComponent TopHinge2;

	UPROPERTY(DefaultComponent, Attach = PillarTop)
	USceneComponent TopHinge3;

	UPROPERTY(DefaultComponent, Attach = PillarTop)
	USceneComponent TopHinge4;

	UPROPERTY(DefaultComponent, Attach = PillarRoot)
	USceneComponent PillarBottom;

	UPROPERTY(DefaultComponent, Attach = PillarBottom)
	USceneComponent BottomHinge1;

	UPROPERTY(DefaultComponent, Attach = PillarBottom)
	USceneComponent BottomHinge2;

	UPROPERTY(DefaultComponent, Attach = PillarBottom)
	USceneComponent BottomHinge3;

	UPROPERTY(DefaultComponent, Attach = PillarBottom)
	USceneComponent BottomHinge4;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackablePillarCapability");

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat PitchCurve;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RaisePillarTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike HideTopTimeLike;

	TArray<USceneComponent> TopHinges;
	TArray<USceneComponent> BottomHinges;

	float CurrentProgress = 0.0;
	float PlayerInput = 0.0;

	FHazeAcceleratedFloat AccSpeed;

	bool bReachedBottom = false;
	bool bWasEverHacked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		TopHinges.Add(TopHinge1);
		TopHinges.Add(TopHinge2);
		TopHinges.Add(TopHinge3);
		TopHinges.Add(TopHinge4);

		BottomHinges.Add(BottomHinge1);
		BottomHinges.Add(BottomHinge2);
		BottomHinges.Add(BottomHinge3);
		BottomHinges.Add(BottomHinge4);

		RaisePillarTimeLike.BindUpdate(this, n"UpdateRaisePillar");
		HideTopTimeLike.BindUpdate(this, n"UpdateHideTop");

		HackComp.OnHackingStarted.AddUFunction(this, n"Hacked");
	}

	UFUNCTION()
	private void Hacked()
	{
		bWasEverHacked = true;
		RaisePillarTimeLike.PlayFromStart();

		URemoteHackablePillarEffectEventHandler::Trigger_Hacked(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWasEverHacked)
		{
			AccSpeed.AccelerateTo(3.0, 1.0, DeltaTime);
			CurrentProgress = Math::Clamp(CurrentProgress + (AccSpeed.Value * DeltaTime), 0.0, 1.0);
		}

		float TopOffset = Math::Lerp(2000.0, 1200.0, CurrentProgress);

		float CurrentAlpha = PitchCurve.GetFloatValue(CurrentProgress);

		for (USceneComponent TopHinge : TopHinges)
		{
			FRotator Rot = TopHinge.RelativeRotation;
			Rot.Pitch = CurrentAlpha * 89.9;
			TopHinge.SetRelativeRotation(Rot);
		}

		for (USceneComponent BottomHinge : BottomHinges)
		{
			FRotator Rot = BottomHinge.RelativeRotation;
			Rot.Pitch = CurrentAlpha * -89.9;
			BottomHinge.SetRelativeRotation(Rot);
		}

		PillarTop.SetRelativeLocation(FVector(0.0, 0.0, TopOffset));

		if (CurrentAlpha >= 1.0)
		{
			ReachedBottom();
		}
	}

	UFUNCTION()
	private void UpdateRaisePillar(float CurValue)
	{
		float Offset = Math::Lerp(800.0, 1200.0, CurValue);
		PillarBottom.SetRelativeLocation(FVector(0.0, 0.0, Offset));
	}

	void UpdateProgress(float Input)
	{
		PlayerInput = Input;
	}

	void ReachedBottom()
	{
		if (bReachedBottom)
			return;

		bReachedBottom = true;
		HackComp.SetHackingAllowed(false);

		HideTopTimeLike.PlayFromStart();

		BP_ReachedBottom();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ReachedBottom() {}
	
	UFUNCTION()
	private void UpdateHideTop(float CurValue)
	{
		float Offset = Math::Lerp(0.0, -140.0, CurValue);
		HackableRoot.SetRelativeLocation(FVector(0.0, 0.0, Offset));
	}
}

class URemoteHackablePillarCapability : URemoteHackableBaseCapability
{
	ARemoteHackablePillar Pillar;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Pillar = Cast<ARemoteHackablePillar>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		/*FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Down;
		Player.ShowTutorialPrompt(TutorialPrompt, this);*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			Pillar.UpdateProgress(Input.X);
		}
	}
}