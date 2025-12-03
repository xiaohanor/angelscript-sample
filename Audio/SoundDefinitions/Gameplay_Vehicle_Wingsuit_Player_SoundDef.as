
UCLASS(Abstract)
class UGameplay_Vehicle_Wingsuit_Player_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnActivateWingsuit(){}

	UFUNCTION(BlueprintEvent)
	void OnDeactivateWingsuit(){}

	UFUNCTION(BlueprintEvent)
	void OnBarrelRoll(FWingSuitBarrelRollEffectParams Params){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY()
	UAudioReflectionComponent ReflectionComponent;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		auto WingSuit = Cast<AWingSuit>(HazeOwner);
		if (WingSuit != nullptr)
		{
			DefaultEmitter.AudioComponent.SetRelativeRotation(FRotator(90,0,0));
			
			ReflectionComponent = UAudioReflectionComponent::Get(WingSuit.PlayerOwner);
		}
	}

}