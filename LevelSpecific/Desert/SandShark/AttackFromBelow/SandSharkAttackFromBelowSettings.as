namespace SandShark
{
	USTRUCT(Meta = (ComposedStruct))
	struct FAttackFromBelowData
	{
		UPROPERTY()
		float AttackWhenWithinDistance = 300;

		UPROPERTY()
		float MaxHeightAboveSand = 1000;

		UPROPERTY()
		bool bActivateAfterTime = false;

		//Time before warping to player location and attacking, only used if bActivateAfterTime is true
		UPROPERTY()
		float TimeBeforeCanAttack = 1;
	};

	namespace AttackFromBelow
	{
		const float TimeBeforeKill = 0.2;
		const float DiveDuration = 1;
	}
}