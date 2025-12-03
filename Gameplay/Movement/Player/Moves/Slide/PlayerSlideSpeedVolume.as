
UCLASS(HideCategories = "Navigation Collision Rendering Debug Actor Cooking")
class APlayerSlideSpeedVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer");
	default BrushComponent.LineThickness = 3.0;
	default SetBrushColor(FLinearColor::Teal);

	// We can safely disable overlap updates when this moves, because players always update overlaps every frame
	default BrushComponent.bDisableUpdateOverlapsOnComponentMove = true;

	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (InlineEditConditionToggle))
	bool bOverrideSlideTargetSpeed = false;

	/**
	 * When not going downhill or uphill, stabilize our sliding speed at this target.
	 * NB: Temporary slides always have a target speed of 0, and will slow down on even ground.
	 */
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "bOverrideSlideTargetSpeed"))
	float SlideTargetSpeed = 750.0;

	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (InlineEditConditionToggle))
	bool bOverrideSlideMinimumSpeed = false;

	/**
	 * Minimum speed that we can slide at.
	 * For forced slides, speed will never drop below this.
	 * For temporary slides, if we go below this speed we will stop sliding.
	 */
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "bOverrideSlideMinimumSpeed"))
	float SlideMinimumSpeed = 400.0;

	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (InlineEditConditionToggle))
	bool bOverrideSlideMaximumSpeed = false;

	/**
	 * Maximum speed that we can slide at.
	 * We will never exceed this speed when going downhill.
	 */
	UPROPERTY(EditAnywhere, Category = "Slide", Meta = (EditCondition = "bOverrideSlideMaximumSpeed"))
	float SlideMaximumSpeed = 1500.0;

	UPROPERTY(EditAnywhere, Category = "Slide")
	UPlayerSlideSettings SettingsOverride;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnActorBeginOverlap.AddUFunction(this, n"OnPlayerBeginOverlap");
		OnActorEndOverlap.AddUFunction(this, n"OnPlayerEndOverlap");
	}

	UFUNCTION()
	void OnPlayerBeginOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(SettingsOverride != nullptr)
			Player.ApplySettings(SettingsOverride, this);

		if (bOverrideSlideTargetSpeed)
			UPlayerSlideSettings::SetSlideTargetSpeed(Player, SlideTargetSpeed, this);
		if (bOverrideSlideMinimumSpeed)
			UPlayerSlideSettings::SetSlideMinimumSpeed(Player, SlideMinimumSpeed, this);
		if (bOverrideSlideMaximumSpeed)
			UPlayerSlideSettings::SetSlideMaximumSpeed(Player, SlideMaximumSpeed, this);
	}

	UFUNCTION()
	void OnPlayerEndOverlap(AActor OverlappedActor, AActor OtherActor)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(SettingsOverride != nullptr)
			Player.ClearSettingsByInstigator(this);

		if (bOverrideSlideTargetSpeed)
			UPlayerSlideSettings::ClearSlideTargetSpeed(Player,this);
		if (bOverrideSlideMinimumSpeed)
			UPlayerSlideSettings::ClearSlideMinimumSpeed(Player, this);
		if (bOverrideSlideMaximumSpeed)
			UPlayerSlideSettings::ClearSlideMaximumSpeed(Player, this);
	}
}