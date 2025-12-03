
UCLASS(Abstract)
class UCharacter_Boss_Summit_RubyKnight_MeleeShockwave_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASummitKnightGenericAttackShockwave MeleeShockwave;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MeleeShockwave = Cast<ASummitKnightGenericAttackShockwave>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return MeleeShockwave.bIsLaunched == true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return MeleeShockwave.bIsLaunched == false;
	}
}