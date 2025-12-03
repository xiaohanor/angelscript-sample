enum ESketchbookDemonBossSubPhase
{
	None,
	JumpToEdge,
	FlyToCorner,
	Shoot
}

class USketchbookDemonBossComponent : USketchbookBossComponent
{
	ESketchbookDemonBossSubPhase SubPhase = ESketchbookDemonBossSubPhase::None;
	float ProjectileFiringYaw = 20;


	void StartMainAttackSequence() override
	{
		Super::StartMainAttackSequence();
		SubPhase = ESketchbookDemonBossSubPhase::JumpToEdge;
	}

	void EndMainAttackSequence() override
	{
		Super::EndMainAttackSequence();
		SubPhase = ESketchbookDemonBossSubPhase::None;
	}
};