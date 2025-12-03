event void FIslandOverseerPhaseComponentPhaseChangeSignature(EIslandOverseerPhase NewPhase, EIslandOverseerPhase OldPhase);

enum EIslandOverseerPhase
{
	Idle,
	IntroCombat,
	Flood,
	PovCombat,
	SideChase,
	TowardsChase,
	Door,
	DoorCutHead,
	Dead
}

class UIslandOverseerPhaseComponent : UActorComponent
{
	EIslandOverseerPhase InternalPhase = EIslandOverseerPhase::Idle;
	FIslandOverseerPhaseComponentPhaseChangeSignature OnPhaseChange;

	UPROPERTY(BlueprintReadOnly)
	const float IntroCombatHalfHealthThreshold = 2.5;

	UPROPERTY(BlueprintReadOnly)
	const float IntroCombatHealthThreshold = 2;

	UPROPERTY(BlueprintReadOnly)
	const float PovCombatHealthThreshold = 1.5;

	UPROPERTY(BlueprintReadOnly)
	const float TowardsChaseHealthThreshold = 1;

	UPROPERTY(BlueprintReadOnly)
	const float DoorHealthThreshold = 0.75;

	UPROPERTY(BlueprintReadOnly)
	const float DoorCutHeadHealthThreshold = 0.5;

	UFUNCTION()
	EIslandOverseerPhase GetPhase() property
	{
		return InternalPhase;
	}

	UFUNCTION()
	void SetPhase(EIslandOverseerPhase InPhase) property
	{
		bool bNewPhase = InPhase != InternalPhase;
		EIslandOverseerPhase OldPhase = InternalPhase;
		InternalPhase = InPhase;
		if(bNewPhase)
			OnPhaseChange.Broadcast(InPhase, OldPhase);
	}
}