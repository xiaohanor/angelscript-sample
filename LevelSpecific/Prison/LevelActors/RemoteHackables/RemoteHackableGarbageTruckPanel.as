event void FRemoteHackableGarbageTruckPanelEvent();
class ARemoteHackableGarbageTruckPanel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PanelRoot;

	UPROPERTY(DefaultComponent, Attach = PanelRoot)
	USceneComponent ScreenRoot;

	UPROPERTY(DefaultComponent, Attach = ScreenRoot)
	UTextRenderComponent MaxWeightTextComp;

	UPROPERTY(DefaultComponent, Attach = ScreenRoot)
	UTextRenderComponent CurrentWeightTextComp;

	UPROPERTY(DefaultComponent, Attach = PanelRoot)
	URemoteHackingResponseComponent HackComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"RemoteHackableGarbageTruckPanelCapability");

	UPROPERTY()
	FRemoteHackableGarbageTruckPanelEvent OnWeightExceeded;

	UPROPERTY(EditAnywhere)
	float MaxWeight = 10000.0;

	float MinWeight = 500.0;
	float DefaultWeight = 353.0;
	float CurrentWeight = 353.0;

	UPROPERTY(DefaultComponent, BlueprintHidden, NotEditable)
	UHazeCrumbSyncedFloatComponent SyncedCurrentMaxWeight;
	default SyncedCurrentMaxWeight.SetValue(MaxWeight);

	int PlayerAmount = 0.0;
	float WeightPerPlayer = 80.0;

	bool bWeightExceeded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		CurrentWeight = DefaultWeight;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		const float CurrentMaxWeight = Math::Clamp(SyncedCurrentMaxWeight.Value, MinWeight, MaxWeight);

		int ClosestInt = Math::TruncToInt(CurrentMaxWeight);
		FString MaxWeightString;
		MaxWeightString += ClosestInt;
		MaxWeightTextComp.SetText(FText::FromString(MaxWeightString));

		CurrentWeight = Math::FInterpTo(CurrentWeight, DefaultWeight + (PlayerAmount * WeightPerPlayer), DeltaTime, 5.0);
		CurrentWeight = Math::Clamp(CurrentWeight, DefaultWeight, MaxWeight);
		int ClosestIntCur = Math::TruncToInt(CurrentWeight);
		FString CurWeightString;
		CurWeightString += ClosestIntCur;
		CurrentWeightTextComp.SetText(FText::FromString(CurWeightString));

		if (HasControl() && !bWeightExceeded)
		{
			if (CurrentWeight >= CurrentMaxWeight)
				CrumbWeightExceeded();
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbWeightExceeded()
	{
		if (bWeightExceeded)
			return;

		bWeightExceeded = true;
		OnWeightExceeded.Broadcast();
	}
}

class URemoteHackableGarbageTruckPanelCapability : URemoteHackableBaseCapability
{
	ARemoteHackableGarbageTruckPanel Panel;

	FHazeAcceleratedFloat AccSpeed;
	float MaxSpeed = 4000.0;
	float TargetSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();

		Panel = Cast<ARemoteHackableGarbageTruckPanel>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		TargetSpeed = 0.0;
		AccSpeed.SnapTo(0.0);

		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		Player.ShowTutorialPrompt(TutorialPrompt, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.RemoveTutorialPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			TargetSpeed = Input.X * MaxSpeed;

			AccSpeed.AccelerateTo(TargetSpeed, 1.5, DeltaTime);
			Panel.SyncedCurrentMaxWeight.Value += AccSpeed.Value * DeltaTime;
		}
	}
}