enum ESketchbookDuckBossSubPhase
{
	None,
	Flying,
	Land,
	StartFlying
}

class USketchbookDuckBossComponent : USketchbookBossComponent
{
	ESketchbookDuckBossSubPhase SubPhase;

	//Flying
	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const int LapsPerAttack = 2; //How many times should it "bounce" on the wall before going back to jumping behavior

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float FlyingYaw = 160;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float FlyingPitchOffset = 5;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float BobSpeed = 5;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float BobStrength = 40;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float HoverHeight = 700;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float FlySpeed = 500;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float LiftSpeed = 500;

	UPROPERTY(EditDefaultsOnly, Category = "Flying")
	const float LandSpeed = 700;

	//Drop egg

	UPROPERTY(EditDefaultsOnly, Category = "Eggs")
	const float DropEggYaw = 160;

	UPROPERTY(EditDefaultsOnly, Category = "Eggs")
	const float TimeBetweenEggs = 0.75;
	
	//Jump
	UPROPERTY()
	FRuntimeFloatCurve JumpCurve;

	int CurrentLaps = 0;

	bool bCanDropEgg = false;
	bool bIsGoingLeft = false;


	void StartMainAttackSequence() override
	{
		Super::StartMainAttackSequence();
		SubPhase = ESketchbookDuckBossSubPhase::StartFlying;
	}

	void EndMainAttackSequence() override
	{
		Super::EndMainAttackSequence();
		SubPhase = ESketchbookDuckBossSubPhase::None;
	}
};