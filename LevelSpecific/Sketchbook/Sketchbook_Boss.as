enum ESketchbookBossChoice
{
	None,
	Demon,
	Crab,
	Duck
}

enum ESketchbookBossAttack
{
	None,
	StompClosePlayer,
	StompNextPlayer1,
	StompNextPlayer2,
	Projectile,
	ChoiceAttack
}

UCLASS(Abstract)
class ASketchbook_Boss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	ESketchbookBossChoice BossSelect;

	UPROPERTY()
	ESketchbookBossChoice PrevBossSelect;

	UPROPERTY()
	ESketchbookBossAttack BossAttack;

	UPROPERTY(DefaultComponent)
	USketchbookArrowResponseComponent ResponseComp;

};
