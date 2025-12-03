struct FPrisonStealthEnemyOnShootOnPlayerParams
{
	UPROPERTY()
	FVector PlayerLocation;
};

UCLASS(Abstract)
class UPrisonStealthEnemyEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	APrisonStealthEnemy Enemy;

	UPROPERTY(BlueprintReadOnly)
	UPrisonStealthDetectionComponent MioDetectionComp;

	UPROPERTY(BlueprintReadOnly)
	UPrisonStealthDetectionComponent ZoeDetectionComp;

	UPROPERTY(BlueprintReadOnly)
	UPrisonStealthStunnedComponent StunComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Enemy = Cast<APrisonStealthEnemy>(Owner);
		
		MioDetectionComp = Enemy.MioDetectionComp;
		ZoeDetectionComp = Enemy.ZoeDetectionComp;

		StunComp = UPrisonStealthStunnedComponent::Get(Owner);
	}

	/**
	 * A player has been detected, meaning that we will soon kill it
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnPlayerDetected() { }

	/**
	 * We fired our weapon at the player, this triggers once per shot
	 */
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnShootOnPlayer(FPrisonStealthEnemyOnShootOnPlayerParams Params) { }
};