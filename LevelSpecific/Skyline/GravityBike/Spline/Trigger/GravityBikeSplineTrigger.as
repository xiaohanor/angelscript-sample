event void FGravityBikeSplineTriggerOnEnter(AGravityBikeSpline GravityBike, UGravityBikeSplineTriggerComponent TriggerComp);
event void FGravityBikeSplineTriggerOnExit(AGravityBikeSpline GravityBike, UGravityBikeSplineTriggerComponent TriggerComp);

enum EGravityBikeSplineTriggerSettingType
{
	Boost,
	Gravity,
	MaxSpeed,
	NoTurnReferenceDelay,
	ForceThrottle,
	AutoAim,
	BlockEnemyRifleFire,
	BlockEnemySlowRifleFire,
	AutoSteer,
	BlockJump,
}

enum EGravityBikeSplineTriggerClearCondition
{
	OnExit,
	OnLanding,
	Duration,
}

struct FGravityBikeSplineTriggerSetting
{
	UPROPERTY()
	EGravityBikeSplineTriggerSettingType Type;

	/**
	 * If true, we still give visual feedback as if we jumped, but we don't add any impulse
	 */
	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::Boost", EditConditionHides))
	bool bBlockJump = true;

	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::Gravity", EditConditionHides))
	float Gravity = 0;

	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::MaxSpeed", EditConditionHides))
	float MaxSpeed = 0;

	UPROPERTY()
	TArray<EGravityBikeSplineTriggerClearCondition> ClearConditions;

	// Only used if one of the ClearConditions is Duration
	UPROPERTY()
	float Duration;

	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::AutoAim", EditConditionHides))
	FGravityBikeSplineAutoAimData AutoAimSettings;

	/**
	 * Where to auto steer towards.
	 */
	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::AutoSteer", EditConditionHides))
	FGravityBikeSplineAutoSteerSettings AutoSteerSettings;

	UPROPERTY(Meta = (EditCondition = "Type == EGravityBikeSplineTriggerSettingType::AutoAim || Type == EGravityBikeSplineTriggerSettingType::AutoSteer", EditConditionHides))
	EInstigatePriority Priority = EInstigatePriority::Low;
}

UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement = "110"))
class AGravityBikeSplineTrigger : APlayerTrigger
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.65, 0.0, 1.0));
	default bTriggerForZoe = false;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UGravityBikeSplineTriggerEditorComponent EditorComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Trigger")
	TArray<FGravityBikeSplineTriggerSetting> SettingsToApply;

	UPROPERTY(EditAnywhere, Category = "Trigger")
	bool bOnlyTriggerWhenGrounded = true;

	UPROPERTY()
	FGravityBikeSplineTriggerOnEnter OnGravityBikeEnter;

	UPROPERTY()
	FGravityBikeSplineTriggerOnExit OnGravityBikeExit;

#if EDITOR
    UPROPERTY(DefaultComponent)
    UEditorBillboardComponent EditorBillboard;
    default EditorBillboard.SpriteName = "S_TriggerBox";
	default EditorBillboard.RelativeScale3D = FVector(5);
#endif

	private TArray<AGravityBikeSpline> WaitingForGroundedGravityBikes;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SetActorControlSide(GravityBikeSpline::GetDriverPlayer());

        Super::BeginPlay();
		
        OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
        OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");

		for(FGravityBikeSplineTriggerSetting& Setting : SettingsToApply)
		{
#if EDITOR
			if(Setting.ClearConditions.IsEmpty())
			{
				PrintWarning(f"Setting on {this} has no clear conditions, and will stick around forever!");
			}
#endif

			switch(Setting.Type)
			{
				case EGravityBikeSplineTriggerSettingType::AutoSteer:
					// Transform from relative to world space on BeginPlay
					Setting.AutoSteerSettings.AutoSteerTargetRotation = ActorTransform.TransformRotation(Setting.AutoSteerSettings.AutoSteerTargetRotation);
					break;

				default:
					break;
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for(int i = WaitingForGroundedGravityBikes.Num() - 1; i >= 0; i--)
		{
			auto GravityBike = WaitingForGroundedGravityBikes[i];
			if(!GravityBike.IsAirborne.Get())
			{
				auto TriggerComp = UGravityBikeSplineTriggerComponent::Get(GravityBike);
				
				TriggerComp.ApplyTrigger(this);
				OnGravityBikeEnter.Broadcast(GravityBike, TriggerComp);

				WaitingForGroundedGravityBikes.RemoveAtSwap(i);
			}
		}
	}

    UFUNCTION()
    private void OnPlayerEnter(AHazePlayerCharacter Player)
    {
		auto DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		if(DriverComp == nullptr)
			return;

		auto GravityBike = DriverComp.GravityBike;
		if(GravityBike == nullptr)
			return;

		auto TriggerComp = UGravityBikeSplineTriggerComponent::Get(GravityBike);
		if(TriggerComp == nullptr)
			return;

		TriggerComp.CurrentTriggers.Add(this);

		if(bOnlyTriggerWhenGrounded && GravityBike.IsAirborne.Get())
		{
			WaitingForGroundedGravityBikes.AddUnique(GravityBike);
			UpdateTicking();
			return;
		}
		
		TriggerComp.ApplyTrigger(this);
		OnGravityBikeEnter.Broadcast(GravityBike, TriggerComp);
    }

    UFUNCTION()
    private void OnPlayerLeave(AHazePlayerCharacter Player)
    {
		auto DriverComp = UGravityBikeSplineDriverComponent::Get(Player);
		if(DriverComp == nullptr)
			return;

		auto GravityBike = DriverComp.GravityBike;
		if(GravityBike == nullptr)
			return;

		auto TriggerComp = UGravityBikeSplineTriggerComponent::Get(GravityBike);
		if(TriggerComp == nullptr)
			return;

		TriggerComp.CurrentTriggers.Remove(this);

		if(bOnlyTriggerWhenGrounded)
		{
			WaitingForGroundedGravityBikes.Remove(GravityBike);
			UpdateTicking();
		}
		
		OnGravityBikeExit.Broadcast(GravityBike, TriggerComp);
    }

	bool ShouldTick() const
	{
		if(!WaitingForGroundedGravityBikes.IsEmpty())
			return true;

		return false;
	}

	void UpdateTicking()
	{
		SetActorTickEnabled(ShouldTick());
	}
};

#if EDITOR
class UGravityBikeSplineTriggerEditorComponent : UActorComponent
{
};

class UGravityBikeSplineTriggerEditorComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineTriggerEditorComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Trigger = Cast<AGravityBikeSplineTrigger>(Component.Owner);
		if(Trigger == nullptr)
			return;

		for(const FGravityBikeSplineTriggerSetting& Setting : Trigger.SettingsToApply)
		{
			switch(Setting.Type)
			{
				case EGravityBikeSplineTriggerSettingType::AutoSteer:
					VisualizeAutoSteer(Trigger, Setting);
					break;

				default:
					break;
			}
		}
	}

	void VisualizeAutoSteer(AGravityBikeSplineTrigger Trigger, FGravityBikeSplineTriggerSetting Setting) const
	{
		FVector AutoSteerDirection = Setting.AutoSteerSettings.AutoSteerTargetRotation.ForwardVector;

		if(!Editor::IsPlaying())
			AutoSteerDirection = Trigger.ActorTransform.TransformVectorNoScale(AutoSteerDirection);

		DrawArrow(Trigger.ActorLocation, Trigger.ActorLocation + AutoSteerDirection * 1000, FLinearColor::Teal, 100, 50);
	}
};
#endif