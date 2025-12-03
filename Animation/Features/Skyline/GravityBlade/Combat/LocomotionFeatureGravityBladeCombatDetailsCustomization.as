class ULocomotionFeatureGravityBladeCombatDetailCustomization : UHazeScriptDetailCustomization
{
	default DetailClass = ULocomotionFeatureGravityBladeCombat;

	ULocomotionFeatureGravityBladeCombat Feature;

	UFUNCTION(BlueprintOverride)
	void CustomizeDetails()
	{
		Feature = Cast<ULocomotionFeatureGravityBladeCombat>(GetCustomizedObject());
		if(Feature == nullptr)
			return;

		Feature.AnimData.InteractionGroundAttacks.SetNum(EGravityBladeCombatInteractionType::MAX);
		Feature.AnimData.InteractionAirAttacks.SetNum(EGravityBladeCombatInteractionType::MAX);
	}
}