class USummitRollKnockBackToPointZoneComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, Category = "Setup")
	AActor PointToHit;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FVector HitLocationOffset;
	
	APlayerTrigger Trigger;

	TOptional<float> TimeStampOverridenKnockBackTarget;

	UTeenDragonRollComponent RollComp;

	const float TimeUntilClearOverride = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Trigger = Cast<APlayerTrigger>(Owner);
		devCheck(Trigger != nullptr, f"{this.Name} was not attached to a player trigger, it will not work then");

		Trigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");

		RollComp = UTeenDragonRollComponent::Get(Game::GetZoe());
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		if(Player.IsZoe())
		{
			if(RollComp == nullptr)
				RollComp = UTeenDragonRollComponent::Get(Player);
			RollComp.OverriddenKnockBackComponent.Set(this);
			TimeStampOverridenKnockBackTarget.Set(Time::GameTimeSeconds);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(TimeStampOverridenKnockBackTarget.IsSet())
		{
			if(Time::GetGameTimeSince(TimeStampOverridenKnockBackTarget.Value) > TimeUntilClearOverride)
			{
				RollComp.OverriddenKnockBackComponent.Reset();
			}
		}
	}
};

#if EDITOR
class USummitRollKnockBackToPointZoneComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitRollKnockBackToPointZoneComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitRollKnockBackToPointZoneComponent>(Component);
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