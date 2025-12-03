class USummitMageModeComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	ESummitMageMode Mode = ESummitMageMode::Ranged;
}

enum ESummitMageMode
{
	Ranged,
	Melee,
	Mixed,
	MAX
}