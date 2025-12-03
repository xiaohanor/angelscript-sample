
enum EPlayerSplineLockZoneUpdateType
{
	Always,
	OnlyWhileGrounded,
	OnlyManually
}

UCLASS(Meta = (HighlightPlacement))
class APlayerSplineLockZone : APlayerTrigger
{
	UPROPERTY(EditAnywhere, Category = "Settings", Meta = (ShowOnlyInnerProperties), AdvancedDisplay)
	FPlayerMovementSplineLockProperties LockProperties;

	UPROPERTY(EditAnywhere, Category = "Settings")
	UPlayerSplineLockRubberBandSettings RubberBandSettings = nullptr; 

	UPROPERTY(EditAnywhere, Category = "Settings")
	UPlayerSplineLockEnterSettings EnterSettings = nullptr;

	/** When will the zone update the current spline for the player */
	UPROPERTY(EditAnywhere, Category = "Settings", AdvancedDisplay)
	EPlayerSplineLockZoneUpdateType UpdateType = EPlayerSplineLockZoneUpdateType::Always;

	/**
	 * Set the player's gameplay perspective mode while they are in this spline lock volume.
	 */
	UPROPERTY(EditAnywhere, Category = "Gameplay Perspective")
	bool bOverrideGameplayPerspectiveMode = false;

	UPROPERTY(EditAnywhere, Category = "Gameplay Perspective", Meta = (EditCondition = "bOverrideGameplayPerspectiveMode"))
	EPlayerMovementPerspectiveMode PerspectiveMode = EPlayerMovementPerspectiveMode::ThirdPerson;

	UPROPERTY(EditInstanceOnly, Category = "Splines")
	TArray<ASplineActor> AvailableSplines;

	/** Collect all spline actors inside the zone */
	UFUNCTION(CallInEditor, Category = "Splines")
	void UpdateSplinesInZone()
	{
		AvailableSplines.Reset();

		auto AllSplineActors = Editor::GetAllEditorWorldActorsOfClass(ASplineActor);

		for(auto It : AllSplineActors)
		{
			auto SplineActor = Cast<ASplineActor>(It);
			if(SplineActor.Level != Level)
				continue;

			FSplinePosition CurrentSplinePosition = SplineActor.Spline.GetSplinePositionAtSplineDistance(0);
			while(true)
			{
				FVector FoundLocation;
				float DistanceFromZone = BrushComponent.GetClosestPointOnCollision(CurrentSplinePosition.WorldLocation, FoundLocation);
				
				if(DistanceFromZone <= KINDA_SMALL_NUMBER)
				{
					// This one is inside
					AvailableSplines.Add(SplineActor);
					break;
				}
				else if(!CurrentSplinePosition.Move(100.0))
				{
					// No move places to move
					break;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		OnPlayerEnter.AddUFunction(this, n"OnPlayerTriggerEnter");
		OnPlayerLeave.AddUFunction(this, n"OnPlayerTriggerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerTriggerEnter(AHazePlayerCharacter Player)
	{
		auto PlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player);
		if(PlayerSplineLockComponent == nullptr)
			return;

		PlayerSplineLockComponent.ActivateSplineZone(this);
		Player.ApplyGameplayPerspectiveMode(PerspectiveMode, this);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnPlayerTriggerLeave(AHazePlayerCharacter Player)
	{
		auto PlayerSplineLockComponent = UPlayerSplineLockComponent::Get(Player);
		if(PlayerSplineLockComponent == nullptr)
			return;

		PlayerSplineLockComponent.DeactivateSplineZone(this);
		Player.ClearGameplayPerspectiveMode(this);
	}
}