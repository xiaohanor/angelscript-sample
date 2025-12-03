enum ESketchbookBossPhase
{
	Jump,
	MainAttack
}

class USketchbookBossComponent : UActorComponent
{
	ESketchbookBossPhase CurrentPhase = ESketchbookBossPhase::Jump;

	ASketchbookBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ASketchbookBoss>(Owner);
	}

	void StartMainAttackSequence()
	{
		CurrentPhase = ESketchbookBossPhase::MainAttack;
	}

	void EndMainAttackSequence()
	{
		CurrentPhase = ESketchbookBossPhase::Jump;
	}
};