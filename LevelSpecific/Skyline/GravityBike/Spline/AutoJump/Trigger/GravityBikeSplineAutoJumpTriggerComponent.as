UCLASS(NotBlueprintable, HideCategories = "Debug Activation Cooking Tags AssetUserData Navigation")
class UGravityBikeSplineAutoJumpTriggerComponent : UActorComponent
{
	UPROPERTY(EditInstanceOnly, Category = "Auto Jump Trigger")
	AGravityBikeSplineAutoJumpTarget Target;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Target == nullptr)
		{
			PrintError(f"AutoJumpTrigger {this} has no Target assigned!");
			return;
		}

		APlayerTrigger PlayerTrigger = Cast<APlayerTrigger>(Owner);
		if(PlayerTrigger != nullptr)
		{
			PlayerTrigger.OnPlayerLeave.AddUFunction(this, n"OnLeave");
			return;
		}
	}
	UFUNCTION()
	private void OnLeave(AHazePlayerCharacter Player)
	{
		check(Player.IsMio());
		AGravityBikeSpline GravityBike = GravityBikeSpline::GetGravityBike();

		auto AutoJumpComp = UGravityBikeSplineAutoJumpComponent::Get(GravityBike);
		if(AutoJumpComp == nullptr)
			return;

		AutoJumpComp.SetTarget(Target);
	}
};

#if EDITOR
class UGravityBikeSplineAutoJumpTriggerComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineAutoJumpTriggerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto AutoJumpTriggerComp = Cast<UGravityBikeSplineAutoJumpTriggerComponent>(Component);
		if(AutoJumpTriggerComp == nullptr)
			return;

		if(AutoJumpTriggerComp.Target != nullptr)
		{
			DrawArrow(AutoJumpTriggerComp.Owner.ActorLocation, AutoJumpTriggerComp.Target.ActorLocation, FLinearColor::Purple, 500, 50);
		}
	}
};
#endif