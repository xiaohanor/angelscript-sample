class AGravityBikeFreeTrigger : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.0, 0.65, 0.0, 1.0));

	UPROPERTY(EditAnywhere)
	bool bForceBoost = false;
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bForceBoost"))
	float BoostDuration = 2;

	UPROPERTY(EditAnywhere)
	bool bLowGravity = false;
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bLowGravity"))
	float GravityScale = 0.5;

	UPROPERTY(EditAnywhere)
	bool bSetMaxSpeed = false;
	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bSetMaxSpeed"))
	float NewMaxSpeed = 5000;

#if EDITOR
    UPROPERTY(DefaultComponent)
    UEditorBillboardComponent EditorBillboard;
    default EditorBillboard.SpriteName = "S_TriggerBox";
	default EditorBillboard.RelativeScale3D = FVector(0.5);
#endif

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Super::BeginPlay();
		
        OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
        OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
    }

    UFUNCTION()
    private void OnPlayerEnter(AHazePlayerCharacter Player)
    {
		AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);

		if(bForceBoost)
		{
			auto FreeBoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
			if(FreeBoostComp != nullptr)
			{
				FreeBoostComp.ApplyForceBoost(true, this);
				FreeBoostComp.SetBoostUntilTime(Time::GameTimeSeconds + BoostDuration);
			}
		}

		if(bLowGravity)
			UMovementGravitySettings::SetGravityScale(GravityBike, GravityScale, this);

		if(bSetMaxSpeed)
			UGravityBikeFreeSettings::SetMaxSpeed(GravityBike, NewMaxSpeed, this, EHazeSettingsPriority::Override);
    }

    UFUNCTION()
    private void OnPlayerLeave(AHazePlayerCharacter Player)
    {
		AGravityBikeFree GravityBike = GravityBikeFree::GetGravityBike(Player);

		if(bForceBoost)
		{
			auto BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
			if(BoostComp != nullptr)
				BoostComp.ClearForceBoost(this);
		}

		if(bLowGravity)
			UMovementGravitySettings::ClearGravityScale(GravityBike,  this);

		if(bSetMaxSpeed)
			UGravityBikeFreeSettings::ClearMaxSpeed(GravityBike, this);
    }
}