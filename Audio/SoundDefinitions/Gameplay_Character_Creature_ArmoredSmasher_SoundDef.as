
UCLASS(Abstract)
class UGameplay_Character_Creature_ArmoredSmasher_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnArmorMelted(){}

	UFUNCTION(BlueprintEvent)
	void OnDeath(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AAISummitArmoredSmasher ArmoredSmasher;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		ArmoredSmasher = Cast<AAISummitArmoredSmasher>(HazeOwner);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Normalized Movement Speed"))
	float GetNormalizedMovementSpeed()
	{
		return Math::Min(1, Math::Abs(ArmoredSmasher.AnimComp.SpeedForward) / 850);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Melt Alpha"))
	float GetMeltAlpha()
	{
		return ArmoredSmasher.MeltingComp.GetMeltAlpha();
	}
}