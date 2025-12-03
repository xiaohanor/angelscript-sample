class ABabyDragonTailClimbFreeFormHorizontalLockVolume : APlayerTrigger
{
#if EDITOR
	UPROPERTY(DefaultComponent)
	UBabyDragonTailClimbFreeFormHorizontalLockVolumeDummyComp DummyComp;
#endif
	UPROPERTY(EditAnywhere, Category = "Setup")
	ASplineActor SplineLockActor;

	default bTriggerForMio = false;
	default bTriggerForZoe = true;

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
		auto DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;

		DragonComp.HorizontalLockVolume.Set(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto DragonComp = UPlayerTailBabyDragonComponent::Get(Player);
		if(DragonComp == nullptr)
			return;

		DragonComp.HorizontalLockVolume.Reset();
	}
};

#if EDITOR
class UBabyDragonTailClimbFreeFormHorizontalLockVolumeDummyComp : UActorComponent{}

class UBabyDragonTailClimbFreeFormHorizontalLockVolumeVisualizerComponent : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBabyDragonTailClimbFreeFormHorizontalLockVolumeDummyComp;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<UBabyDragonTailClimbFreeFormHorizontalLockVolumeDummyComp>(Component);
		if(Comp == nullptr)
			return;
		auto Volume = Cast<ABabyDragonTailClimbFreeFormHorizontalLockVolume>(Component.Owner);
		if(Volume == nullptr)
			return;

		DrawArrow(Volume.ActorLocation, Volume.ActorLocation + Volume.ActorForwardVector * 500, FLinearColor::Red, 40, 5, false);
	}	
}
#endif