UCLASS(Abstract)
class AIslandWalkerDisplays : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Sprite;
#endif
	
	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UWidgetComponent WidgetComp;
	default WidgetComp.bVisible = false;
	default WidgetComp.ManuallyRedraw = true;
	default WidgetComp.DrawSize = FVector2D(600, 300);
	default WidgetComp.TickWhenOffscreen = true;

	UPROPERTY(EditInstanceOnly)
	AActor DisplayProp;

	UPROPERTY(EditInstanceOnly)
	EHazePlayer Player;
	default Player = EHazePlayer::Mio;

	bool bIsCompleted;

	UPROPERTY(Transient, VisibleInstanceOnly)
	UTextureRenderTarget2D WidgetRenderTarget;

	bool bInitialized = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bInitialized)
			return;
		if (!IsValid(DisplayProp))
			return;

		// Hack: Move the widget away so we can't see it, but it still renders
		WidgetComp.SetVisibility(true);
		WidgetComp.SetRelativeLocation(FVector(0, 0, 99999999));

		auto Widget = Cast<UIslandWalkerDisplayWidget>(WidgetComp.GetWidget());
		if (IsValid(Widget))
			Widget.UpdateState(Player, bIsCompleted);

		WidgetComp.RequestRenderUpdate();
		WidgetRenderTarget = WidgetComp.GetRenderTarget();
		if (WidgetRenderTarget != nullptr)
		{
			auto StaticMesh = UStaticMeshComponent::Get(DisplayProp);
			UMaterialInstanceDynamic DynamicMaterial = StaticMesh.CreateDynamicMaterialInstance(0);
			DynamicMaterial.SetTextureParameterValue(n"_SE", WidgetRenderTarget);

			bInitialized = true;
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	void ActivateDisplay()
	{
		bIsCompleted = true;

		if (IsValid(DisplayProp))
		{
			auto Widget = Cast<UIslandWalkerDisplayWidget>(WidgetComp.GetWidget());
			if (IsValid(Widget))
				Widget.UpdateState(Player, bIsCompleted);
			WidgetComp.RequestRenderUpdate();
		}
	}

	UFUNCTION()
	void CountDownCompleted()
	{
		ActivateDisplay();
	}
};

UCLASS(Abstract)
class UIslandWalkerDisplayWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UWidget MioActive;
	UPROPERTY(BindWidget)
	UWidget MioDisabled;

	UPROPERTY(BindWidget)
	UWidget ZoeActive;
	UPROPERTY(BindWidget)
	UWidget ZoeDisabled;

	void UpdateState(EHazePlayer TargetPlayer, bool bActive)
	{
		MioActive.Visibility = (TargetPlayer == EHazePlayer::Mio && bActive) ? ESlateVisibility::Visible : ESlateVisibility::Hidden;
		MioDisabled.Visibility = (TargetPlayer == EHazePlayer::Mio && !bActive) ? ESlateVisibility::Visible : ESlateVisibility::Hidden;
		ZoeActive.Visibility = (TargetPlayer == EHazePlayer::Zoe && bActive) ? ESlateVisibility::Visible : ESlateVisibility::Hidden;
		ZoeDisabled.Visibility = (TargetPlayer == EHazePlayer::Zoe && !bActive) ? ESlateVisibility::Visible : ESlateVisibility::Hidden;
	}
}