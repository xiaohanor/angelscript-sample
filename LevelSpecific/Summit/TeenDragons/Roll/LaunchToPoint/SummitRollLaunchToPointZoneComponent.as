enum ESummitRollLaunchToPointZoneMode
{
	LeavingGround,
	EnteringZone
}

class USummitRollLaunchToPointZoneComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	AActor PointToHit;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector HitLocationOffset;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ESummitRollLaunchToPointZoneMode Mode = ESummitRollLaunchToPointZoneMode::LeavingGround;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bShouldOnlyTriggerIfGoingTowardsTarget = true;

	APlayerTrigger Trigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger = Cast<APlayerTrigger>(Owner);
		devCheck(Trigger != nullptr, f"{this.Name} was not attached to a player trigger, it will not work then");

		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		Trigger.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		auto RollComp = UTeenDragonRollComponent::Get(Player);
		if(RollComp != nullptr)
		{
			RollComp.RollLaunchToPointZonesInside.AddUnique(this);
		}
	}
	

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		auto RollComp = UTeenDragonRollComponent::Get(Player);
		if(RollComp != nullptr)
		{
			RollComp.RollLaunchToPointZonesInside.RemoveSingleSwap(this);
		}
	}

	FVector GetLandingLocation()
	{	
		if(PointToHit == nullptr)
			return WorldLocation + HitLocationOffset;
		else
			return PointToHit.ActorLocation + HitLocationOffset;
	}
};
#if EDITOR
class USummitRollLaunchToPointZoneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollLaunchToPointZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollLaunchToPointZoneComponent>(Component);
		if(!ensure((Comp != nullptr) && (Comp.Owner != nullptr)))
			return;
		
		FVector TargetLocation;
		if(Comp.PointToHit != nullptr)
			TargetLocation = Comp.PointToHit.ActorLocation + Comp.HitLocationOffset;
		else
			TargetLocation = Comp.WorldLocation + Comp.HitLocationOffset;
		DrawArrow(Comp.WorldLocation, TargetLocation, FLinearColor::Red, 40, 10);
		DrawWireSphere(TargetLocation, 20, FLinearColor::Green, 10);
	}
}
#endif